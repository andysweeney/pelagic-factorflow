/* ================================================================
 * Pelagic Solutions — Buyer Insights Analytics (Layer 2)
 * ================================================================
 *
 * Pure computation module. Takes the raw rows for one upload and
 * returns a per-currency stats bundle ready for Layer 3 rendering.
 *
 * Inputs:
 *   uploadMeta   — { buyer_label, notes, date_range_min, date_range_max, ... }
 *   invoiceRows  — array of buyer_invoices rows (from Supabase)
 *   cnRows       — array of buyer_credit_notes rows (from Supabase, optional)
 *
 * Excluded rows (`excluded === true`) are skipped entirely. This is the
 * operator's way of saying "this row is junk — ignore in analysis."
 *
 * The module is intentionally numerical-only: no archetype labels,
 * no narrative copy, no thresholds-as-classification. Layer 3 decides
 * what to call things. Layer 2 just computes the numbers.
 *
 * No DOM access, no Supabase access — this file can be unit-tested
 * in Node by requiring it and feeding rows. The IIFE at the bottom
 * exposes the entry point on `window` for the browser case.
 * ================================================================ */

(function(global) {
    'use strict';

    // ── Public entry point ─────────────────────────────────────────
    //
    // Returns the full stats bundle. Shape:
    //   {
    //     uploadMeta:    { ...passthrough... },
    //     overall:       { totalInvoices, totalCNs, totalSuppliers, currencies },
    //     perCurrency:   { GBP: {...}, EUR: {...}, ... },
    //     warnings:      [ "Strings the operator should see" ]
    //   }

    function computeBuyerStats(uploadMeta, invoiceRows, cnRows) {
        invoiceRows = (invoiceRows || []).filter(function(r) { return !r.excluded; });
        cnRows      = (cnRows || []).filter(function(r) { return !r.excluded; });

        var warnings = [];
        if (invoiceRows.length === 0) {
            warnings.push("No non-excluded invoice rows; analysis will be empty.");
        }

        // Bucket by currency. Each currency report is independent — Pelagic agreed
        // up-front that buyer reports are per-currency rather than FX-converted.
        var byCcy = {};
        invoiceRows.forEach(function(r) {
            var ccy = normCcy(r.currency);
            if (!ccy) return;
            if (!byCcy[ccy]) byCcy[ccy] = { invoices: [], cns: [] };
            byCcy[ccy].invoices.push(r);
        });
        cnRows.forEach(function(r) {
            var ccy = normCcy(r.currency);
            if (!ccy) return;
            // It's normal for a CN currency to not appear in invoices (typo, or all
            // invoices in that currency were excluded). Warn but don't drop.
            if (!byCcy[ccy]) {
                byCcy[ccy] = { invoices: [], cns: [] };
                warnings.push("Credit notes in " + ccy + " have no matching invoices in the same currency.");
            }
            byCcy[ccy].cns.push(r);
        });

        var perCurrency = {};
        Object.keys(byCcy).forEach(function(ccy) {
            perCurrency[ccy] = computeForCurrency(byCcy[ccy].invoices, byCcy[ccy].cns);
        });

        // Overall (cross-currency) headline numbers — counts only, no monetary
        // mixing. Useful for the report's "your supply chain at a glance" opener.
        var allSuppliers = {};
        invoiceRows.forEach(function(r) { if (r.supplier_identifier) allSuppliers[r.supplier_identifier] = true; });

        var overall = {
            totalInvoices:  invoiceRows.length,
            totalCNs:       cnRows.length,
            totalSuppliers: Object.keys(allSuppliers).length,
            currencies:     Object.keys(perCurrency).sort(),
            dateRangeMin:   minDate(invoiceRows.map(function(r) { return r.invoice_date; })),
            dateRangeMax:   maxDate(invoiceRows.map(function(r) { return r.invoice_date; }))
        };

        return {
            uploadMeta:  uploadMeta || {},
            overall:     overall,
            perCurrency: perCurrency,
            warnings:    warnings
        };
    }

    // ── Per-currency core ──────────────────────────────────────────

    function computeForCurrency(invoices, cns) {
        // Group invoices by supplier identifier. supplier_identifier is the
        // buyer's internal vendor key — the operator's primary handle on a supplier.
        var bySupplier = {};
        invoices.forEach(function(inv) {
            var sid = inv.supplier_identifier;
            if (!sid) return;
            if (!bySupplier[sid]) {
                bySupplier[sid] = {
                    identifier: sid,
                    name: inv.supplier_name || sid,
                    invoices: [],
                    cns: []
                };
            }
            // Prefer the first non-empty name we see — buyer extracts sometimes
            // have blank names on some rows.
            if (!bySupplier[sid].name && inv.supplier_name) bySupplier[sid].name = inv.supplier_name;
            bySupplier[sid].invoices.push(inv);
        });
        cns.forEach(function(cn) {
            var sid = cn.supplier_identifier;
            if (!sid) return;
            // If a CN names a supplier with no invoices in this currency, fabricate
            // an entry so the dilution rate denominator is zero (handled in stats).
            // Surfaces orphaned CNs in the report rather than dropping them silently.
            if (!bySupplier[sid]) {
                bySupplier[sid] = {
                    identifier: sid,
                    name: cn.supplier_name || sid,
                    invoices: [],
                    cns: []
                };
            }
            bySupplier[sid].cns.push(cn);
        });

        var totalSpend = sum(invoices, function(r) { return numericAmount(r.amount); });
        var totalCNs   = sum(cns,      function(r) { return numericAmount(r.amount); });

        // Per-supplier stats
        var suppliers = Object.keys(bySupplier).map(function(sid) {
            return computeSupplierStats(bySupplier[sid], totalSpend);
        });

        // Sort by total spend, descending. Used everywhere downstream — concentration
        // calculations assume sorted-descending input.
        suppliers.sort(function(a, b) { return b.totalSpend - a.totalSpend; });

        return {
            totals:           computeTotals(invoices, cns, suppliers, totalSpend, totalCNs),
            suppliers:        suppliers,
            concentration:    computeConcentration(suppliers, totalSpend),
            paymentBehaviour: computePaymentBehaviour(invoices, suppliers),
            dilution:         computeDilution(suppliers, totalSpend, totalCNs),
            volumeOverTime:   computeVolumeOverTime(invoices)
        };
    }

    // ── Single-supplier stats ──────────────────────────────────────

    function computeSupplierStats(sup, currencyTotalSpend) {
        var invoices = sup.invoices;
        var cns      = sup.cns;

        var totalSpend = sum(invoices, function(r) { return numericAmount(r.amount); });
        var cnTotal    = sum(cns,      function(r) { return numericAmount(r.amount); });
        var dilutionRate = totalSpend > 0 ? cnTotal / totalSpend : 0;

        var invDates = invoices.map(function(r) { return r.invoice_date; }).filter(Boolean).sort();
        var firstInvoice = invDates[0] || null;
        var lastInvoice  = invDates[invDates.length - 1] || null;

        // Payment behaviour — only computable when paid_date is populated.
        // Days-past-due is (paid_date - due_date). Negative means paid early.
        var daysPastDueArr = [];
        var paidCount = 0;
        var unpaidCount = 0;
        invoices.forEach(function(inv) {
            if (inv.paid_date && inv.due_date) {
                var d = daysBetween(inv.due_date, inv.paid_date);
                if (d !== null) {
                    daysPastDueArr.push(d);
                    paidCount++;
                }
            } else {
                unpaidCount++;
            }
        });

        var paymentCoveragePct = invoices.length > 0 ? paidCount / invoices.length : 0;
        var avgDaysPastDue    = daysPastDueArr.length > 0 ? mean(daysPastDueArr) : null;
        var medianDaysPastDue = daysPastDueArr.length > 0 ? median(daysPastDueArr) : null;
        var onTimePct = daysPastDueArr.length > 0
            ? daysPastDueArr.filter(function(d) { return d <= 0; }).length / daysPastDueArr.length
            : null;
        var latePct = daysPastDueArr.length > 0
            ? daysPastDueArr.filter(function(d) { return d > 0; }).length / daysPastDueArr.length
            : null;
        var veryLatePct = daysPastDueArr.length > 0
            ? daysPastDueArr.filter(function(d) { return d > 30; }).length / daysPastDueArr.length
            : null;

        // Volume distribution over time — monthly buckets.
        var monthly = bucketByMonth(invoices);
        var monthlyCount = mapValues(monthly, function(bucket) { return bucket.length; });
        var monthlyAmount = mapValues(monthly, function(bucket) {
            return sum(bucket, function(r) { return numericAmount(r.amount); });
        });

        // Trend: linear regression slope on monthly invoice count.
        // Slope normalised by mean to be comparable across suppliers of different size.
        // Positive = growing volume, negative = declining, near-zero = flat.
        // Layer 3 picks the labelling thresholds; Layer 2 just returns the number.
        var months = Object.keys(monthlyCount).sort();
        var counts = months.map(function(m) { return monthlyCount[m]; });
        var trendSlope = counts.length >= 3 ? linearSlope(counts) : null;
        var trendSlopeNormalised = trendSlope !== null && mean(counts) > 0
            ? trendSlope / mean(counts)
            : null;

        return {
            identifier:           sup.identifier,
            name:                 sup.name,
            invoiceCount:         invoices.length,
            totalSpend:           round2(totalSpend),
            sharePct:             currencyTotalSpend > 0 ? totalSpend / currencyTotalSpend : 0,
            avgInvoiceAmount:     invoices.length > 0 ? round2(totalSpend / invoices.length) : 0,
            firstInvoice:         firstInvoice,
            lastInvoice:          lastInvoice,
            activeMonths:         months.length,

            paidCount:            paidCount,
            unpaidCount:          unpaidCount,
            paymentCoveragePct:   paymentCoveragePct,
            avgDaysPastDue:       avgDaysPastDue !== null ? round1(avgDaysPastDue) : null,
            medianDaysPastDue:    medianDaysPastDue,
            onTimePct:            onTimePct,
            latePct:              latePct,
            veryLatePct:          veryLatePct,

            cnCount:              cns.length,
            cnTotal:              round2(cnTotal),
            dilutionRate:         dilutionRate,

            monthlyInvoiceCount:  monthlyCount,
            monthlyInvoiceAmount: mapValues(monthlyAmount, function(v) { return round2(v); }),
            trendSlope:           trendSlope,
            trendSlopeNormalised: trendSlopeNormalised
        };
    }

    // ── Per-currency totals ────────────────────────────────────────

    function computeTotals(invoices, cns, suppliers, totalSpend, totalCNs) {
        var allDpd = [];
        invoices.forEach(function(inv) {
            if (inv.paid_date && inv.due_date) {
                var d = daysBetween(inv.due_date, inv.paid_date);
                if (d !== null) allDpd.push(d);
            }
        });

        return {
            invoiceCount:  invoices.length,
            cnCount:       cns.length,
            supplierCount: suppliers.length,
            totalSpend:    round2(totalSpend),
            totalCNs:      round2(totalCNs),
            netSpend:      round2(totalSpend - totalCNs),
            dilutionRate:  totalSpend > 0 ? totalCNs / totalSpend : 0,
            avgInvoiceAmount: invoices.length > 0 ? round2(totalSpend / invoices.length) : 0,
            // DSO/DPO surrogate — average days from invoice_date to paid_date
            // for paid invoices only. This is what the supplier "feels" as
            // payment latency. Not the same as days-past-due, which uses due_date.
            avgDaysToPaid: computeAvgDaysToPaid(invoices),
            paymentCoveragePct: invoices.length > 0
                ? invoices.filter(function(i) { return !!i.paid_date; }).length / invoices.length
                : 0,
            avgDaysPastDue:    allDpd.length > 0 ? round1(mean(allDpd)) : null,
            medianDaysPastDue: allDpd.length > 0 ? median(allDpd) : null
        };
    }

    function computeAvgDaysToPaid(invoices) {
        var days = [];
        invoices.forEach(function(inv) {
            if (inv.paid_date && inv.invoice_date) {
                var d = daysBetween(inv.invoice_date, inv.paid_date);
                if (d !== null) days.push(d);
            }
        });
        return days.length > 0 ? round1(mean(days)) : null;
    }

    // ── Concentration ──────────────────────────────────────────────
    //
    // suppliers is already sorted by totalSpend desc, so top-N is just slice.
    // HHI is sum of squared market shares (each as a fraction 0..1). 0 = perfectly
    // diversified across many suppliers, 1 = total concentration on one.

    function computeConcentration(suppliers, totalSpend) {
        var spends = suppliers.map(function(s) { return s.totalSpend; });
        var hhi = totalSpend > 0
            ? spends.reduce(function(acc, sp) { var share = sp / totalSpend; return acc + share * share; }, 0)
            : 0;

        return {
            supplierCount: suppliers.length,
            top1Pct:  totalSpend > 0 ? topNSum(spends, 1)  / totalSpend : 0,
            top3Pct:  totalSpend > 0 ? topNSum(spends, 3)  / totalSpend : 0,
            top5Pct:  totalSpend > 0 ? topNSum(spends, 5)  / totalSpend : 0,
            top10Pct: totalSpend > 0 ? topNSum(spends, 10) / totalSpend : 0,
            hhi:      hhi
        };
    }

    function topNSum(arr, n) {
        var s = 0;
        for (var i = 0; i < Math.min(n, arr.length); i++) s += arr[i];
        return s;
    }

    // ── Payment behaviour (currency-wide) ──────────────────────────

    function computePaymentBehaviour(invoices, suppliers) {
        var allDpd = [];
        invoices.forEach(function(inv) {
            if (inv.paid_date && inv.due_date) {
                var d = daysBetween(inv.due_date, inv.paid_date);
                if (d !== null) allDpd.push(d);
            }
        });

        var coveragePct = invoices.length > 0
            ? invoices.filter(function(i) { return !!i.paid_date; }).length / invoices.length
            : 0;

        // Distribution: how many invoices fall into each lateness band?
        // Bands chosen to match the report's payment-behaviour section.
        var buckets = {
            earlyOrOnTime:    0,  // d <= 0
            late1to14:        0,  // 1 <= d <= 14
            late15to30:       0,  // 15 <= d <= 30
            late31to60:       0,  // 31 <= d <= 60
            late61plus:       0   // d > 60
        };
        allDpd.forEach(function(d) {
            if (d <= 0) buckets.earlyOrOnTime++;
            else if (d <= 14) buckets.late1to14++;
            else if (d <= 30) buckets.late15to30++;
            else if (d <= 60) buckets.late31to60++;
            else buckets.late61plus++;
        });

        // Suppliers whose median days-past-due > 30 across at least 3 paid invoices.
        // Threshold chosen to surface the "consistently late" set without false
        // positives from a single bad month. Returns names + numbers; Layer 3 chooses
        // how (or whether) to surface them.
        var consistentlyLate = suppliers.filter(function(s) {
            return s.paidCount >= 3 && s.medianDaysPastDue !== null && s.medianDaysPastDue > 30;
        }).map(function(s) {
            return {
                identifier:        s.identifier,
                name:              s.name,
                medianDaysPastDue: s.medianDaysPastDue,
                avgDaysPastDue:    s.avgDaysPastDue,
                paidCount:         s.paidCount
            };
        }).sort(function(a, b) { return b.medianDaysPastDue - a.medianDaysPastDue; });

        return {
            coveragePct:        coveragePct,
            paidInvoiceCount:   allDpd.length,
            avgDaysPastDue:     allDpd.length > 0 ? round1(mean(allDpd)) : null,
            medianDaysPastDue:  allDpd.length > 0 ? median(allDpd) : null,
            distribution:       buckets,
            consistentlyLate:   consistentlyLate
        };
    }

    // ── Dilution ───────────────────────────────────────────────────

    function computeDilution(suppliers, totalSpend, totalCNs) {
        // League: suppliers ranked by dilution rate, but only those with enough
        // invoice base to be meaningful (>=3 invoices and non-zero spend).
        // A single invoice with one CN gives 100% dilution but isn't a signal.
        var league = suppliers
            .filter(function(s) { return s.invoiceCount >= 3 && s.totalSpend > 0; })
            .map(function(s) {
                return {
                    identifier:   s.identifier,
                    name:         s.name,
                    dilutionRate: s.dilutionRate,
                    cnTotal:      s.cnTotal,
                    cnCount:      s.cnCount,
                    invoiceTotal: s.totalSpend,
                    invoiceCount: s.invoiceCount,
                    sharePct:     s.sharePct
                };
            })
            .sort(function(a, b) { return b.dilutionRate - a.dilutionRate; });

        return {
            overallRate:    totalSpend > 0 ? totalCNs / totalSpend : 0,
            totalCNs:       round2(totalCNs),
            cnInvoiceRatio: totalSpend > 0 ? totalCNs / totalSpend : 0,
            league:         league
        };
    }

    // ── Volume over time (currency-wide) ───────────────────────────

    function computeVolumeOverTime(invoices) {
        var monthly = bucketByMonth(invoices);
        var months = Object.keys(monthly).sort();
        return months.map(function(m) {
            return {
                month:        m,
                invoiceCount: monthly[m].length,
                totalSpend:   round2(sum(monthly[m], function(r) { return numericAmount(r.amount); }))
            };
        });
    }

    // ── Helpers ────────────────────────────────────────────────────

    function normCcy(c) {
        if (!c) return null;
        var s = String(c).trim().toUpperCase();
        return s || null;
    }

    function numericAmount(a) {
        if (a == null || a === '') return 0;
        var n = typeof a === 'number' ? a : parseFloat(a);
        return isFinite(n) ? n : 0;
    }

    function sum(arr, fn) {
        var s = 0;
        for (var i = 0; i < arr.length; i++) s += fn(arr[i]);
        return s;
    }

    function mean(arr) {
        if (arr.length === 0) return 0;
        return sum(arr, function(x) { return x; }) / arr.length;
    }

    function median(arr) {
        if (arr.length === 0) return null;
        var sorted = arr.slice().sort(function(a, b) { return a - b; });
        var mid = Math.floor(sorted.length / 2);
        return sorted.length % 2 === 1
            ? sorted[mid]
            : (sorted[mid - 1] + sorted[mid]) / 2;
    }

    function daysBetween(fromDateStr, toDateStr) {
        if (!fromDateStr || !toDateStr) return null;
        var a = new Date(fromDateStr + 'T00:00:00');
        var b = new Date(toDateStr + 'T00:00:00');
        if (isNaN(a.getTime()) || isNaN(b.getTime())) return null;
        return Math.round((b - a) / (1000 * 60 * 60 * 24));
    }

    function minDate(arr) {
        var f = arr.filter(Boolean).sort();
        return f[0] || null;
    }

    function maxDate(arr) {
        var f = arr.filter(Boolean).sort();
        return f[f.length - 1] || null;
    }

    function bucketByMonth(invoices) {
        // Buckets by YYYY-MM of invoice_date. Returns { "2025-05": [rows], "2025-06": [rows], ... }
        var out = {};
        invoices.forEach(function(inv) {
            if (!inv.invoice_date) return;
            var m = inv.invoice_date.slice(0, 7);
            if (!out[m]) out[m] = [];
            out[m].push(inv);
        });
        return out;
    }

    function mapValues(obj, fn) {
        var out = {};
        Object.keys(obj).forEach(function(k) { out[k] = fn(obj[k]); });
        return out;
    }

    function linearSlope(yArr) {
        // Simple linear regression of y against index (0..n-1). Returns slope.
        // Used as a trend indicator: positive = growing, negative = declining.
        var n = yArr.length;
        if (n < 2) return 0;
        var xs = []; for (var i = 0; i < n; i++) xs.push(i);
        var xMean = mean(xs), yMean = mean(yArr);
        var num = 0, den = 0;
        for (var j = 0; j < n; j++) {
            num += (xs[j] - xMean) * (yArr[j] - yMean);
            den += (xs[j] - xMean) * (xs[j] - xMean);
        }
        return den === 0 ? 0 : num / den;
    }

    function round2(n) { return Math.round(n * 100) / 100; }
    function round1(n) { return Math.round(n * 10) / 10; }

    // ── Export ─────────────────────────────────────────────────────
    // Expose on global for the browser, and on module.exports for Node test.

    var api = { computeBuyerStats: computeBuyerStats };

    if (typeof module !== 'undefined' && module.exports) {
        module.exports = api;
    } else {
        global.BuyerAnalytics = api;
    }

})(typeof window !== 'undefined' ? window : globalThis);
