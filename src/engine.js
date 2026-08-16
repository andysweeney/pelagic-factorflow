// FactorFlow calculation engine — extracted verbatim from Dashboard.jsx v6.32
// (sha256 66faa059a04f4890642b3ba18a889244721753b32a35cdbd7ec68784309ca0ab).
//
// Every function body below is a byte-for-byte slice of the source file. The
// only additions are this header, the createEngine wrapper and the export
// block at the foot. No React, no Supabase, no DOM: runs unchanged in the
// browser bundle and in a Deno/Supabase Edge Function.
//
// The four data collections plus CREDIT_NOTES_DB and the three rate constants
// are injected rather than read from module scope. The clock is injected as
// refDate and remains mutable through setAppToday(), exactly as in the file:
// processForDate() relies on that side channel in the fundingHeadroom block.
//
// KNOWN DEFECT CARRIED OVER VERBATIM — see notes: processForDate() calls
// auditLog(), which is declared inside the FactoringDashboard component and
// is therefore not in scope here, exactly as it is not in scope at module
// scope in Dashboard.jsx. The call throws ReferenceError in both. Left
// unfixed so the comparison harness measures extraction, not repair.

export function createEngine(deps) {
  var INVOICES_DB        = deps.INVOICES_DB;
  var FUNDING_PROGRAMS_DB = deps.FUNDING_PROGRAMS_DB;
  var SUPPLIERS_DB       = deps.SUPPLIERS_DB;
  var BUYERS_DB          = deps.BUYERS_DB;
  var CREDIT_NOTES_DB    = deps.CREDIT_NOTES_DB || [];
  var ADVANCE_RATE       = deps.ADVANCE_RATE;
  var ANNUAL_RATE        = deps.ANNUAL_RATE;
  var PENALTY_RATE       = deps.PENALTY_RATE;
  var REF_DATE           = deps.REF_DATE;

  var _APP_TODAY = REF_DATE;
  function appToday() { return _APP_TODAY; }
  function setAppToday(d) { _APP_TODAY = d || REF_DATE; }

var ELIG_REASONS = {
  CURRENCY:          "Invoice currency does not match the programme",
  SUPPLIER_NOT_ELIG: "Supplier entity is not on the programme's eligible list",
  BUYER_NOT_ELIG:    "Buyer entity is not on the programme's eligible list",
  INV_STATUS_BUY:    "Invoice status is blocked from purchase on this programme",
  INV_STATUS_FUND:   "Invoice status is blocked from funding on this programme",
  SUPPLIER_PAUSED:   "Supplier is paused",
  BUYER_PAUSED:      "Buyer is paused",
  MAX_INV_SIZE:      "Invoice exceeds the maximum invoice size",
  MIN_INV_SIZE:      "Invoice is below the minimum invoice size",
  MAX_TERM:          "Days to maturity exceed the maximum term",
  MIN_TERM:          "Days to maturity are below the minimum term",
  NO_TERM:           "Invoice has no due date",
  ADVANCE_RATE:      "Supplier advance rate exceeds the programme maximum", // RETIRED 9 Aug 2026: ceiling now caps, not excludes. Label kept for historic audit rows.
  INTEREST_RATE:     "Supplier interest rate is below the programme minimum",
  DIL_SUP_LIVE:      "Supplier dilution (live) exceeds the programme maximum",
  DIL_SUP_30:        "Supplier dilution (30d) exceeds the programme maximum",
  DIL_SUP_90:        "Supplier dilution (90d) exceeds the programme maximum",
  DIL_FUND_LIVE:     "Funded dilution (live) exceeds the programme maximum",
  DIL_FUND_30:       "Funded dilution (30d) exceeds the programme maximum",
  DIL_FUND_90:       "Funded dilution (90d) exceeds the programme maximum"
};

var DEFAULT_PURCHASE_BLOCKED = ["Settled"];

var DEFAULT_FUNDING_BLOCKED  = ["Settled", "Cancelled", "Declined", "Disputed", "Buyer Default"];

function r2(v) { return Math.round(v * 100) / 100; }

function addDays(s, n) { var p = s.split("-"); var d = new Date(Date.UTC(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))); d.setUTCDate(d.getUTCDate() + n); return d.toISOString().split("T")[0]; }

function daysBetween(a, b) { var pa = a.split("-"); var pb = b.split("-"); return Math.round((Date.UTC(parseInt(pb[0]), parseInt(pb[1]) - 1, parseInt(pb[2])) - Date.UTC(parseInt(pa[0]), parseInt(pa[1]) - 1, parseInt(pa[2]))) / 86400000); }

function parseEntityId(entityId) {
  if (!entityId) return { supplierId: null, branchId: null };
  var parts = entityId.split(":");
  return { supplierId: parts[0], branchId: parts[1] || null };
}

function lowestLimit(values) {
  var out = null;
  for (var i = 0; i < values.length; i++) {
    var v = values[i];
    if (v === null || v === undefined || v === "") continue;
    v = parseFloat(v);
    if (isNaN(v)) continue;
    if (out === null || v < out) out = v;
  }
  return out;
}

function _mk(code, detail) {
  return { code: code, label: ELIG_REASONS[code] || code, detail: detail || null };
}

function synthesizeTranches(inv) {
  if (Array.isArray(inv.tranches) && inv.tranches.length > 0) return inv.tranches;
  if (!inv.fundedDate || !(inv.capitalDue > 0)) return [];
  var term = daysBetween(inv.fundedDate, inv.dueDate);
  if (term < 1) term = 1;
  return [{
    trancheId: "T1",
    capital: r2(inv.capitalDue),
    capitalRepaid: 0,
    rate: inv.annualRate || 0,
    advancedDate: inv.fundedDate,
    term: term,
    status: "active"
  }];
}

function tranchesActiveCapital(tranches) {
  if (!Array.isArray(tranches)) return 0;
  return r2(tranches.reduce(function(s, t) { return s + Math.max(0, (t.capital || 0) - (t.capitalRepaid || 0)); }, 0));
}

function tranchesInterestCharged(tranches) {
  if (!Array.isArray(tranches)) return 0;
  return r2(tranches.reduce(function(s, t) {
    var outstanding = Math.max(0, (t.capital || 0) - (t.capitalRepaid || 0));
    if (outstanding <= 0) return s;
    return s + outstanding * ((t.rate || 0) / 360) * (t.term || 0);
  }, 0));
}

function tranchesWeightedRate(tranches) {
  if (!Array.isArray(tranches) || tranches.length === 0) return 0;
  var num = 0, den = 0;
  tranches.forEach(function(t) {
    var outstanding = Math.max(0, (t.capital || 0) - (t.capitalRepaid || 0));
    if (outstanding <= 0) return;
    num += outstanding * (t.rate || 0);
    den += outstanding;
  });
  return den > 0 ? num / den : 0;
}

function applyCapitalRepaymentFIFO(tranches, amount) {
  if (!Array.isArray(tranches) || amount <= 0) return { applied: 0, remaining: amount || 0 };
  // Sort by advancedDate ascending — oldest first
  var ordered = tranches.slice().sort(function(a, b) {
    return (a.advancedDate || "") < (b.advancedDate || "") ? -1 : 1;
  });
  var remaining = amount;
  var applied = 0;
  for (var i = 0; i < ordered.length && remaining > 0.005; i++) {
    var t = ordered[i];
    var outstanding = Math.max(0, (t.capital || 0) - (t.capitalRepaid || 0));
    if (outstanding <= 0.005) continue;
    var take = Math.min(remaining, outstanding);
    t.capitalRepaid = r2((t.capitalRepaid || 0) + take);
    remaining -= take;
    applied += take;
    if (Math.abs((t.capital || 0) - t.capitalRepaid) < 0.005) t.status = "fully_repaid";
    else t.status = "partially_repaid";
  }
  return { applied: r2(applied), remaining: r2(remaining) };
}

function getSupplierById(entityId) {
  if (!entityId) return null;
  var parsed = parseEntityId(entityId);
  return SUPPLIERS_DB.find(function(s) { return s.id === parsed.supplierId; }) || null;
}

function getBranchById(entityId) {
  if (!entityId) return null;
  var parsed = parseEntityId(entityId);
  if (!parsed.branchId) return null;
  var sup = SUPPLIERS_DB.find(function(s) { return s.id === parsed.supplierId; });
  if (!sup || !sup.branches) return null;
  return sup.branches.find(function(b) { return b.branchId === parsed.branchId; }) || null;
}

function getParentEntityId(entityId) {
  if (!entityId) return entityId;
  return parseEntityId(entityId).supplierId;
}

function getParentSupplierName(nameOrId) {
  if (!nameOrId) return nameOrId;
  // If it looks like an ID (SUP-xxx or SUP-xxx:BR-xxx), resolve to name
  if (nameOrId.match && nameOrId.match(/^SUP-/)) {
    var sup = getSupplierById(nameOrId);
    return sup ? sup.name : nameOrId;
  }
  var sep = nameOrId.indexOf(" \u2014 ");
  return sep >= 0 ? nameOrId.substring(0, sep) : nameOrId;
}

function getParentSupplier(nameOrId) {
  if (!nameOrId) return null;
  if (nameOrId.match && nameOrId.match(/^SUP-/)) return getSupplierById(nameOrId);
  var pn = getParentSupplierName(nameOrId);
  return SUPPLIERS_DB.find(function(s) { return s.name === pn; }) || null;
}

function isEntityPaused(entityId) {
  if (!entityId) return false;
  var sup = getSupplierById(entityId);
  if (!sup) return false;
  // Check parent pause first
  if (sup.paused) return true;
  // Check branch pause
  var branch = getBranchById(entityId);
  if (branch && branch.paused) return true;
  return false;
}

function isBuyerPaused(buyerId) {
  if (!buyerId) return false;
  var b = BUYERS_DB.find(function(x) { return x.id === buyerId; });
  return b ? !!b.paused : false;
}

function branchLimitsFor(entityId, key) {
  var parsed = parseEntityId(entityId || "");
  if (!parsed.branchId) return null;
  var parent = getSupplierById(parsed.supplierId);
  if (!parent || !parent.branches) return null;
  var br = parent.branches.find(function(b) { return b.branchId === parsed.branchId; });
  if (!br || !br[key]) return null;
  return br[key];
}

function getSupplierRate(entityId, asOfTimestamp) {
  var supplier = getSupplierById(entityId);
  if (!supplier) {
    // Backward compat: try by name
    supplier = SUPPLIERS_DB.find(function(s) { return s.name === entityId; });
  }
  if (!supplier || !supplier.rates || supplier.rates.length === 0) return { advanceRate: ADVANCE_RATE, annualRate: ANNUAL_RATE, penaltyRate: PENALTY_RATE };
  // One clock. Falls back to the app as-of date so a back-dated or scheduled
  // run resolves the rate that applied on that date, not the rate today.
  var ts = asOfTimestamp || (appToday() + "T23:59:59Z");
  var sorted = supplier.rates.slice().sort(function(a, b) { return (a.effectiveTimestamp || a.effectiveDate).localeCompare(b.effectiveTimestamp || b.effectiveDate); });
  var rate = sorted[0];
  for (var i = 0; i < sorted.length; i++) {
    var rts = sorted[i].effectiveTimestamp || sorted[i].effectiveDate;
    if (rts <= ts) rate = sorted[i];
  }
  return { advanceRate: rate.advanceRate !== undefined ? rate.advanceRate : ADVANCE_RATE, annualRate: rate.annualRate, penaltyRate: rate.penaltyRate };
}

function invoiceTermDays(inv, asOf) {
  if (!inv.dueDate) return null;
  return daysBetween(asOf, inv.dueDate);
}

function getProgramEligibility(inv, supDilRates, asOf) {
  asOf = asOf || appToday();
  var supRate = getSupplierRate(inv.supplierId || inv.supplierName, asOf);
  var entityId = inv.supplierId || "";
  var parentId = getParentEntityId(entityId);
  var parentSup = getParentSupplierName(inv.supplierName);
  var buyerId = inv.buyerId || "";
  var term = invoiceTermDays(inv, asOf);
  var dr = supDilRates ? (supDilRates[parentId] || supDilRates[parentSup] || {}) : {};
  var parentSupObj = getSupplierById(parentId) || getParentSupplier(inv.supplierName);

  var supPaused = isEntityPaused(entityId);
  var buyPaused = isBuyerPaused(buyerId);

  var out = { purchasable: [], fundable: [], rejected: [] };

  FUNDING_PROGRAMS_DB.forEach(function(fp) {
    var buyReasons = [], fundReasons = [];

    // ---- Purchase gates ----------------------------------------------------
    if (fp.currency && inv.currency && fp.currency !== inv.currency) {
      buyReasons.push(_mk("CURRENCY", inv.currency + " vs " + fp.currency));
    }
    // Exact entity match only. The old parent-id fallback made every future
    // branch eligible automatically; the list is now an explicit snapshot.
    if (fp.eligibleSuppliers && fp.eligibleSuppliers.length > 0) {
      if (fp.eligibleSuppliers.indexOf(entityId) === -1) {
        buyReasons.push(_mk("SUPPLIER_NOT_ELIG", entityId));
      }
    }
    if (fp.eligibleBuyers && fp.eligibleBuyers.length > 0) {
      if (fp.eligibleBuyers.indexOf(buyerId) === -1) {
        buyReasons.push(_mk("BUYER_NOT_ELIG", buyerId));
      }
    }
    var buyBlocked = fp.purchaseBlockedStatuses || DEFAULT_PURCHASE_BLOCKED;
    if (buyBlocked.indexOf(inv.invoiceStatus) > -1) {
      buyReasons.push(_mk("INV_STATUS_BUY", inv.invoiceStatus));
    }

    // ---- Funding gates -----------------------------------------------------
    var fundBlocked = fp.fundingBlockedStatuses || DEFAULT_FUNDING_BLOCKED;
    if (fundBlocked.indexOf(inv.invoiceStatus) > -1) {
      fundReasons.push(_mk("INV_STATUS_FUND", inv.invoiceStatus));
    }
    if (supPaused) fundReasons.push(_mk("SUPPLIER_PAUSED", entityId));
    if (buyPaused) fundReasons.push(_mk("BUYER_PAUSED", buyerId));

    // Max invoice size — lowest of programme / parent / branch.
    var maxSize = lowestLimit([
      fp.maxInvoiceSize,
      parentSupObj && parentSupObj.singleInvoiceLimits ? parentSupObj.singleInvoiceLimits[fp.id] : null,
      (function() { var m = branchLimitsFor(entityId, "singleInvoiceLimits"); return m ? m[fp.id] : null; })()
    ]);
    if (maxSize !== null && inv.amount > maxSize) {
      fundReasons.push(_mk("MAX_INV_SIZE", inv.amount + " > " + maxSize));
    }

    // Legacy programme minimum invoice size. Superseded by Minimum Payment Size
    // but retained until that ships.
    if (fp.minInvoiceSize != null && inv.amount < fp.minInvoiceSize) {
      fundReasons.push(_mk("MIN_INV_SIZE", inv.amount + " < " + fp.minInvoiceSize));
    }

    // Term — lowest of programme / parent / branch for the maximum.
    if (term === null) {
      fundReasons.push(_mk("NO_TERM"));
    } else {
      var maxTerm = lowestLimit([
        fp.maxInvoiceTerm,
        parentSupObj && parentSupObj.maxTermLimits ? parentSupObj.maxTermLimits[fp.id] : null,
        (function() { var m = branchLimitsFor(entityId, "maxTermLimits"); return m ? m[fp.id] : null; })()
      ]);
      if (maxTerm !== null && term > maxTerm) {
        fundReasons.push(_mk("MAX_TERM", term + "d > " + maxTerm + "d"));
      }
      var minTerm = (fp.minInvoiceTerm != null) ? fp.minInvoiceTerm : fp.minInvoiceTenor;
      if (minTerm != null && term < minTerm) {
        fundReasons.push(_mk("MIN_TERM", term + "d < " + minTerm + "d"));
      }
    }

    if (fp.minInterestRate != null && supRate.annualRate < fp.minInterestRate - 0.0001) {
      fundReasons.push(_mk("INTEREST_RATE"));
    }
    // Max Advance Rate no longer excludes: a supplier contracted above the
    // programme ceiling is funded AT the ceiling. See effectiveAdvanceRate().
    // Decided 9 August 2026 (handover 7.1).

    if (fp.maxSupDilLive  != null && dr.dilRate  > fp.maxSupDilLive)  fundReasons.push(_mk("DIL_SUP_LIVE"));
    if (fp.maxSupDil30    != null && dr.dil30    > fp.maxSupDil30)    fundReasons.push(_mk("DIL_SUP_30"));
    if (fp.maxSupDil90    != null && dr.dil90    > fp.maxSupDil90)    fundReasons.push(_mk("DIL_SUP_90"));
    if (fp.maxFundDilLive != null && dr.fdilRate > fp.maxFundDilLive) fundReasons.push(_mk("DIL_FUND_LIVE"));
    if (fp.maxFundDil30   != null && dr.fdil30   > fp.maxFundDil30)   fundReasons.push(_mk("DIL_FUND_30"));
    if (fp.maxFundDil90   != null && dr.fdil90   > fp.maxFundDil90)   fundReasons.push(_mk("DIL_FUND_90"));

    // ---- Collect -----------------------------------------------------------
    if (buyReasons.length > 0) {
      out.rejected.push({ programId: fp.id, programName: fp.name, stage: "purchase", reasons: buyReasons });
      return;
    }
    out.purchasable.push(fp);
    if (fundReasons.length > 0) {
      out.rejected.push({ programId: fp.id, programName: fp.name, stage: "funding", reasons: fundReasons });
      return;
    }
    out.fundable.push(fp);
  });

  return out;
}

function getEligiblePrograms(inv, supDilRates, asOf) {
  return getProgramEligibility(inv, supDilRates, asOf).fundable;
}

function getPurchasablePrograms(inv, asOf) {
  return getProgramEligibility(inv, null, asOf).purchasable;
}

function effectiveAdvanceRate(fp, entityId, asOf) {
  var progAR = (fp && fp.maxAdvanceRate != null) ? fp.maxAdvanceRate : null;
  var sr = getSupplierRate(entityId, asOf);
  var supAR = (sr && sr.advanceRate != null) ? sr.advanceRate : null;
  if (supAR == null && progAR == null) return 0;
  if (supAR == null) return progAR;
  if (progAR == null) return supAR;
  return Math.min(supAR, progAR);
}

function getMaxAvailableCapital(inv, supDilRates, cnDilutionTotal, buyerCollected, asOf) {
  var eligible = getEligiblePrograms(inv, supDilRates, asOf);
  if (eligible.length === 0) return 0;
  // Effective fundable base:
  //  - cap at invoice amount (always)
  //  - cap at partialApprovedAmount if the invoice is Approved in Part (buyer won't pay more than that)
  //  - cap at amount minus any credit-note dilutions already applied
  //  - cap at amount minus any buyer payments already collected (the collected portion is no longer a receivable)
  // Funding advance rate applies to the lowest of these.
  var partial = (inv.invoiceStatus === "Approved in Part" && inv.partialApprovedAmount > 0) ? inv.partialApprovedAmount : inv.amount;
  var postDilutions = inv.amount - (cnDilutionTotal || 0);
  var postCollected = inv.amount - (buyerCollected || 0);
  var effectiveBase = Math.max(0, Math.min(inv.amount, partial, postDilutions, postCollected));
  if (effectiveBase <= 0) return 0;
  var maxCap = 0;
  eligible.forEach(function(fp) {
    var cap = r2(effectiveBase * effectiveAdvanceRate(fp, inv.supplierId || inv.supplierName, asOf));
    if (cap > maxCap) maxCap = cap;
  });
  return maxCap;
}

function processForDate(viewDate, paymentsDb, holdbackPaymentsDb) {
  var processed = [];
  var allocsByInvoice = new Map();
  paymentsDb.forEach(function(pay) {
    pay.allocations.forEach(function(a) {
      var effDate = a.allocDate || pay.date;
      if (effDate > viewDate) return;
      if (!allocsByInvoice.has(a.invoiceId)) allocsByInvoice.set(a.invoiceId, []);
      allocsByInvoice.get(a.invoiceId).push({
        paymentId: pay.paymentId, amount: a.amount, date: effDate, currency: pay.currency
      });
    });
  });
  // Credit notes only reduce invoice amount (dilution) — they do NOT flow through the payment waterfall
  var cnDilutionByInvoice = new Map();
  var cnUnallocBySupplier = new Map(); // supplier -> unallocated CN total
  var cnUnallocBySupBuyer = new Map(); // "supplier|buyer" -> unallocated CN total
  var cnUnallocByBuyer = new Map(); // buyer -> unallocated CN total
  CREDIT_NOTES_DB.forEach(function(cn) {
    if (cn.date > viewDate) return;
    var allocated = 0;
    if (cn.allocations) cn.allocations.forEach(function(a) {
      cnDilutionByInvoice.set(a.invoiceId, (cnDilutionByInvoice.get(a.invoiceId) || 0) + a.amount);
      allocated += a.amount;
    });
    var unalloc = r2(cn.amount - allocated);
      // Keyed on parent entity id, never on name. A credit note raised under an
      // old supplier or branch name must still count towards the same supplier,
      // and names on credit_notes are frozen at creation.
      var cnParent = getParentEntityId(cn.supplierId) || getParentSupplierName(cn.supplierName);
      var cnBuyer  = getParentEntityId(cn.buyerId)    || cn.buyerName;
      if (unalloc > 0.01 && cnParent) {
      cnUnallocBySupplier.set(cnParent, (cnUnallocBySupplier.get(cnParent) || 0) + unalloc);
        if (cnBuyer) {
        var key = cnParent + "|" + cnBuyer;
        cnUnallocBySupBuyer.set(key, (cnUnallocBySupBuyer.get(key) || 0) + unalloc);
        cnUnallocByBuyer.set(cnBuyer, (cnUnallocByBuyer.get(cnBuyer) || 0) + unalloc);
        }
      }
  });
  // Build holdback disbursement/application maps per invoice
  var hbDisbursedByInvoice = new Map();
  var hbAppliedToInvoice = new Map();
  holdbackPaymentsDb.forEach(function(hbp) {
    if (hbp.date > viewDate) return;
    hbp.allocations.forEach(function(a) {
      if (a.type === "disbursement") {
        var src = hbp.sourceInvoiceId;
        hbDisbursedByInvoice.set(src, (hbDisbursedByInvoice.get(src) || 0) + a.amount);
      } else if (a.type === "invoice") {
        var src2 = hbp.sourceInvoiceId;
        hbDisbursedByInvoice.set(src2, (hbDisbursedByInvoice.get(src2) || 0) + a.amount);
        if (!hbAppliedToInvoice.has(a.targetId)) hbAppliedToInvoice.set(a.targetId, []);
        hbAppliedToInvoice.get(a.targetId).push({
          hbPaymentId: hbp.hbPaymentId, sourceInvoiceId: src2, amount: a.amount, date: hbp.date, currency: hbp.currency
        });
      }
    });
  });
  INVOICES_DB.forEach(function(rawInv) {
    if (rawInv.invoiceDate > viewDate) return;
    // Backfill tranches array for legacy invoices that pre-date the tranche model.
    // Idempotent — re-running is safe. Persisted on next save (tranches field roundtrips through Supabase).
    if ((!Array.isArray(rawInv.tranches) || rawInv.tranches.length === 0) && rawInv.fundedDate && rawInv.capitalDue > 0) {
      rawInv.tranches = synthesizeTranches(rawInv);
    }
    // Derive capitalDue and interestCharged from tranches (tranches are source of truth).
    // For invoices not yet funded (no tranches), keep the legacy values from the raw record.
    if (Array.isArray(rawInv.tranches) && rawInv.tranches.length > 0) {
      rawInv.capitalDue = tranchesActiveCapital(rawInv.tranches);
      rawInv.interestCharged = tranchesInterestCharged(rawInv.tranches);
      rawInv.annualRate = tranchesWeightedRate(rawInv.tranches);
      rawInv.holdback = r2((rawInv.amount || 0) - rawInv.capitalDue);
      rawInv.deferredPayment = r2(rawInv.holdback - rawInv.interestCharged);
      rawInv.advanceRate = rawInv.amount > 0 ? rawInv.capitalDue / rawInv.amount : 0;
    }
    var statusAsOfDate = "Received", histAsOfDate = [];
    for (var hi = 0; hi < rawInv.invoiceStatusHistory.length; hi++) {
      var hh = rawInv.invoiceStatusHistory[hi];
      if (hh.date <= viewDate) { statusAsOfDate = hh.status; histAsOfDate.push(hh); }
    }
    var paysForInv = (allocsByInvoice.get(rawInv.id) || []).slice().sort(function(a, b) { return a.date < b.date ? -1 : 1; });
    var pastDue = rawInv.dueDate < viewDate;
    var decEntry = histAsOfDate.find(function(x) { return x.status === "Declined"; });
    var dispEntry = histAsOfDate.find(function(x) { return x.status === "Disputed"; });
    var declinedDate = decEntry ? decEntry.date : null;
    var disputedDate = dispEntry ? dispEntry.date : null;
    var daysOverdue = pastDue ? daysBetween(rawInv.dueDate, viewDate) : 0;
    var daysDisputed = (statusAsOfDate === "Disputed" && disputedDate) ? daysBetween(disputedDate, viewDate) : 0;
    // Capital/interest/holdback balances only apply once the invoice is actually funded (money advanced)
    var isFunded = rawInv.fundingStatus !== "pending" && rawInv.fundingStatus !== "purchased" && rawInv.fundedDate;
    var intBal = isFunded ? rawInv.interestCharged : 0, penBal = 0, capBal = isFunded ? rawInv.capitalDue : 0;
    var hbBal = isFunded ? (rawInv.deferredPayment !== undefined && rawInv.deferredPayment !== null ? rawInv.deferredPayment : r2((rawInv.holdback || 0) - (rawInv.interestCharged || 0))) : 0;
    var hbRecd = 0;
    var penaltyAccrued = 0;
    var annotatedPays = [];
    var penaltyStartDate = null;
    if (declinedDate && declinedDate < viewDate) penaltyStartDate = declinedDate;
    else if (rawInv.dueDate < viewDate) penaltyStartDate = rawInv.dueDate;
    var penaltyDays = penaltyStartDate ? daysBetween(penaltyStartDate, viewDate) : 0;
    function cleanBal() { if (Math.abs(penBal) < 0.01) penBal = 0; if (Math.abs(intBal) < 0.01) intBal = 0; if (Math.abs(capBal) < 0.01) capBal = 0; if (Math.abs(hbBal) < 0.01) hbBal = 0; }
    // Reset tranche repayment state — viewData recomputes it deterministically from payments
    if (Array.isArray(rawInv.tranches)) {
      rawInv.tranches.forEach(function(t) { t.capitalRepaid = 0; t.status = "active"; });
    }
    function applyPay(pay, allowPen) {
      var rem = pay.amount, toI = 0, toP = 0, toC = 0, toH = 0;
      if (allowPen && rem > 0 && penBal > 0.005) { var x = Math.min(rem, penBal); penBal -= x; rem -= x; toP = x; }
      if (rem > 0 && intBal > 0.005) { var x2 = Math.min(rem, intBal); intBal -= x2; rem -= x2; toI = x2; }
      if (rem > 0 && capBal > 0.005) { var x3 = Math.min(rem, capBal); capBal -= x3; rem -= x3; toC = x3; }
      if (rem > 0 && hbBal > 0.005) { var x4 = Math.min(rem, hbBal); hbBal -= x4; rem -= x4; toH = x4; hbRecd += x4; }
      cleanBal();
      // Apply capital portion to tranches FIFO (oldest first). Updates capitalRepaid and tranche status.
      if (toC > 0.005 && Array.isArray(rawInv.tranches) && rawInv.tranches.length > 0) {
        applyCapitalRepaymentFIFO(rawInv.tranches, toC);
      }
      annotatedPays.push(Object.assign({}, pay, {
        appliedToInterest: r2(toI), appliedToPenalty: r2(toP), appliedToCapital: r2(toC), appliedToHoldback: r2(toH),
        postCapBal: r2(capBal), postIntBal: r2(intBal), postPenBal: r2(penBal), postHbBal: r2(hbBal)
      }));
    }
    var invPenaltyRate = rawInv.penaltyRate || PENALTY_RATE;
    var invPenaltyDailyRate = invPenaltyRate / 360;
    // Pre-check write-offs: if all capital+interest+penalty would be written off, skip penalty accrual
    var preWoP = 0, preWoI = 0, preWoC = 0;
    if (rawInv.writeOffs) rawInv.writeOffs.forEach(function(wo) { preWoP += wo.penalty || 0; preWoI += wo.interest || 0; preWoC += wo.capital || 0; });
    var woCoversAll = rawInv.writeOffs && preWoC >= rawInv.capitalDue - 0.01 && preWoI >= rawInv.interestCharged - 0.01;
    if (penaltyDays > 0 && (intBal + capBal) > 0.01 && !woCoversAll) {
      var payIdx = 0;
      while (payIdx < paysForInv.length && paysForInv[payIdx].date <= penaltyStartDate) { applyPay(paysForInv[payIdx], false); payIdx++; }
      for (var d = 1; d <= penaltyDays; d++) {
        var today = addDays(penaltyStartDate, d);
        if (capBal > 0.01) { var dayPen = capBal * invPenaltyDailyRate; penBal += dayPen; penaltyAccrued += dayPen; }
        while (payIdx < paysForInv.length && paysForInv[payIdx].date <= today) { applyPay(paysForInv[payIdx], true); payIdx++; }
      }
      while (payIdx < paysForInv.length) { applyPay(paysForInv[payIdx], true); payIdx++; }
    } else {
      paysForInv.forEach(function(p) { applyPay(p, false); });
    }
    var fs;
    cleanBal();
    // Apply write-offs
    var woTotalPen = 0, woTotalInt = 0, woTotalCap = 0, woTotalHb = 0;
    if (rawInv.writeOffs) {
      rawInv.writeOffs.forEach(function(wo) {
        woTotalPen += wo.penalty || 0;
        woTotalInt += wo.interest || 0;
        woTotalCap += wo.capital || 0;
        woTotalHb += wo.holdback || 0;
      });
      penBal = Math.max(0, penBal - woTotalPen);
      intBal = Math.max(0, intBal - woTotalInt);
      capBal = Math.max(0, capBal - woTotalCap);
      hbBal = Math.max(0, hbBal - woTotalHb);
    }
    // Apply adjustments (credits decrease, debits increase)
    var adjCreditPen = 0, adjCreditInt = 0, adjCreditCap = 0, adjDebitPen = 0, adjDebitInt = 0, adjDebitCap = 0;
    if (rawInv.adjustments) {
      rawInv.adjustments.forEach(function(adj) {
        if (adj.type === "credit") { adjCreditPen += adj.penalty || 0; adjCreditInt += adj.interest || 0; adjCreditCap += adj.capital || 0; }
        else { adjDebitPen += adj.penalty || 0; adjDebitInt += adj.interest || 0; adjDebitCap += adj.capital || 0; }
      });
      penBal = Math.max(0, penBal - adjCreditPen + adjDebitPen);
      intBal = Math.max(0, intBal - adjCreditInt + adjDebitInt);
      capBal = Math.max(0, capBal - adjCreditCap + adjDebitCap);
    }
    // Compute balance owed AFTER all payments, write-offs, adjustments, and holdback applications
    var terminalInvStatus = statusAsOfDate === "Cancelled" || statusAsOfDate === "Settled" || statusAsOfDate === "Declined";
    var hbAppsForInv = (hbAppliedToInvoice.get(rawInv.id) || []).slice().sort(function(a, b) { return a.date < b.date ? -1 : 1; });
    var annotatedHbPays = [];
    hbAppsForInv.forEach(function(hbApp) {
      var rem = hbApp.amount, toP = 0, toI = 0, toC = 0;
      if (rem > 0 && penBal > 0.005) { var x = Math.min(rem, penBal); penBal -= x; rem -= x; toP = x; }
      if (rem > 0 && intBal > 0.005) { var x2 = Math.min(rem, intBal); intBal -= x2; rem -= x2; toI = x2; }
      if (rem > 0 && capBal > 0.005) { var x3 = Math.min(rem, capBal); capBal -= x3; rem -= x3; toC = x3; }
      cleanBal();
      // Apply capital portion to tranches FIFO (oldest first)
      if (toC > 0.005 && Array.isArray(rawInv.tranches) && rawInv.tranches.length > 0) {
        applyCapitalRepaymentFIFO(rawInv.tranches, toC);
      }
      annotatedHbPays.push(Object.assign({}, hbApp, {
        appliedToPenalty: r2(toP), appliedToInterest: r2(toI), appliedToCapital: r2(toC)
      }));
    });
    cleanBal();
    var hbDisbursed = r2(hbDisbursedByInvoice.get(rawInv.id) || 0);
    var hbAvailable = r2(hbRecd - hbDisbursed); // Can go negative if payment unallocated after HBP disbursement
    var holdbackOverdrawn = r2(Math.max(0, hbDisbursed - hbRecd)); // Supplier owes this back
    var balOwed = r2(capBal + intBal + penBal + holdbackOverdrawn);
    var debtBal = r2(capBal + intBal + penBal); // Debt balance excluding holdback — used for funding status
    var dilTotal = r2(cnDilutionByInvoice.get(rawInv.id) || 0);
    var amtPostDil = r2(rawInv.amount - dilTotal);
    var initialCapPlusInt = r2(rawInv.capitalDue + rawInv.interestCharged);
    var approvedAmt = rawInv.partialApprovedAmount || 0;
    // Determine the effective approved/diluted amount for status checks
    var effectiveAmt = rawInv.amount;
    if (approvedAmt > 0 && approvedAmt < effectiveAmt) effectiveAmt = approvedAmt;
    if (amtPostDil < effectiveAmt) effectiveAmt = amtPostDil;

    if (rawInv.fundingStatus === "historic") fs = "historic";
    else if (rawInv.fundingStatus === "pending") fs = "pending";
    else if (rawInv.fundingStatus === "purchased" && !terminalInvStatus) fs = "purchased";
    else if (rawInv.fundingStatus === "write_off" && balOwed > 0.01) fs = "write_off";
    else if (rawInv.fundingStatus === "write_off" && debtBal < 0.005) fs = "fully_repaid";
    else if (debtBal < 0.005 && !(rawInv.capitalDue === 0 && rawInv.fundedDate)) fs = "fully_repaid";
    else if ((statusAsOfDate === "Settled" || statusAsOfDate === "Cancelled") && debtBal > 0.01) fs = "recovery_mode";
    else if (statusAsOfDate === "Declined") fs = "recovery_mode";
    else if (rawInv.fundedDate && effectiveAmt < initialCapPlusInt - 0.01) fs = "recovery_mode";
    else if (rawInv.fundedDate && effectiveAmt < rawInv.amount - 0.01) fs = "at_risk";
    else {
      // Get thresholds from program if available, otherwise use defaults
      var prog = rawInv.fundingProgram ? FUNDING_PROGRAMS_DB.find(function(fp) { return fp.id === rawInv.fundingProgram; }) : null;
      var thOverdue = (prog && prog.thresholdOverdue !== undefined) ? prog.thresholdOverdue : 1;
      var thAtRisk = (prog && prog.thresholdAtRisk !== undefined) ? prog.thresholdAtRisk : 7;
      var thRecovery = (prog && prog.thresholdRecovery !== undefined) ? prog.thresholdRecovery : 30;
      var thDisputeAtRisk = (prog && prog.thresholdDisputeAtRisk !== undefined) ? prog.thresholdDisputeAtRisk : 1;
      var thDisputeRecovery = (prog && prog.thresholdDisputeRecovery !== undefined) ? prog.thresholdDisputeRecovery : 14;
      if (statusAsOfDate === "Buyer Default" || statusAsOfDate === "Declined" || daysOverdue > thRecovery || daysDisputed > thDisputeRecovery) fs = "recovery_mode";
      else if (daysOverdue > thAtRisk || (statusAsOfDate === "Disputed" && daysDisputed > thDisputeAtRisk)) fs = "at_risk";
      else if (pastDue && daysOverdue >= thOverdue) fs = "overdue";
      else fs = "funded";
    }
    // Set fullyRepaidDate when invoice transitions to fully_repaid
    if (fs === "fully_repaid" && !rawInv.fullyRepaidDate) {
      // Find the date of the last payment that brought balance to zero
      var lastPayDate = viewDate;
      if (paysForInv.length > 0) lastPayDate = paysForInv[paysForInv.length - 1].date;
      if (hbAppsForInv.length > 0 && hbAppsForInv[hbAppsForInv.length - 1].date > lastPayDate) lastPayDate = hbAppsForInv[hbAppsForInv.length - 1].date;
      rawInv.fullyRepaidDate = lastPayDate;
      // If prior status was recovery_mode, log the legal repurchase event
      if (rawInv.fundingStatus === "recovery_mode" || rawInv.priorFundingStatus === "recovery_mode") {
        auditLog("Repurchased by Supplier", rawInv.id + " (recovery_mode) reached full repayment \u2014 legally repurchased by supplier " + rawInv.supplierName + " on " + lastPayDate, { invoiceId: rawInv.id, amount: rawInv.amount, currency: rawInv.currency, supplierId: rawInv.supplierId, supplier: rawInv.supplierName, buyerId: rawInv.buyerId, buyer: rawInv.buyerName, fullyRepaidDate: lastPayDate, fundingProgram: rawInv.fundingProgram, priorStatus: "recovery_mode" });
      }
    } else if (fs !== "fully_repaid" && rawInv.fullyRepaidDate) {
      // Clear if no longer fully repaid (e.g. payment unallocated)
      rawInv.fullyRepaidDate = null;
    }
    // Remember status for next tick (used for transition-based audit events)
    rawInv.priorFundingStatus = fs;
    var hbApplications = hbAppliedToInvoice.get(rawInv.id) || [];
    // Auto-settle: if total buyer payments >= min(amount, approvedAmount, amountPostDilutions)
    var settleThreshold = rawInv.amount;
    if (rawInv.partialApprovedAmount > 0 && rawInv.partialApprovedAmount < settleThreshold) settleThreshold = rawInv.partialApprovedAmount;
    if (amtPostDil < settleThreshold) settleThreshold = amtPostDil;
    var totalBuyerPaid = 0;
    paysForInv.forEach(function(p) { totalBuyerPaid += p.amount || 0; });
    if (totalBuyerPaid >= settleThreshold - 0.01 && settleThreshold > 0.01 && statusAsOfDate !== "Settled" && statusAsOfDate !== "Cancelled" && statusAsOfDate !== "Declined") {
      // Find the date of the payment that crossed the threshold
      var runningTotal = 0, settlePayDate = viewDate;
      paysForInv.forEach(function(p) { runningTotal += p.amount || 0; if (runningTotal >= settleThreshold - 0.01 && !rawInv.settledDate) settlePayDate = p.date; });
      if (!rawInv.settledDate) {
        rawInv.settledDate = settlePayDate;
        rawInv.invoiceStatusHistory = rawInv.invoiceStatusHistory || [];
        rawInv.invoiceStatusHistory.push({ status: "Settled", date: settlePayDate });
      }
      statusAsOfDate = "Settled";
      // Re-evaluate funding status since settled with balance triggers recovery
      if (fs !== "fully_repaid" && fs !== "write_off" && fs !== "pending" && debtBal > 0.01) fs = "recovery_mode";
    }
    // For unfunded invoices, compute max available capital from eligible programs.
    // supDilRates is deliberately undefined here: dilution rates are derived FROM
    // this function's output, so they cannot be an input to it. The figure therefore
    // ignores dilution ceilings and can overstate what is actually fundable.
    // Known limitation — do not "fix" by passing a variable that does not exist.
    // buyerCollected reduces fundable headroom — the portion already paid by the buyer
    // is no longer a receivable, so we can't advance against it.
    var maxAvailCap = (!isFunded) ? getMaxAvailableCapital(rawInv, undefined, cnDilutionByInvoice.get(rawInv.id) || 0, totalBuyerPaid, viewDate) : 0;
    // Funding headroom for purchased/funded invoices with a current program — used by the top-up workflow
    var fundingHeadroom = 0;
    if (rawInv.fundingProgram && (rawInv.fundingStatus === "purchased" || rawInv.fundingStatus === "funded" || rawInv.fundingStatus === "at_risk" || rawInv.fundingStatus === "overdue")) {
      var currentProg = FUNDING_PROGRAMS_DB.find(function(p) { return p.id === rawInv.fundingProgram; });
      if (currentProg) {
        var hPartial = (rawInv.invoiceStatus === "Approved in Part" && rawInv.partialApprovedAmount > 0) ? rawInv.partialApprovedAmount : rawInv.amount;
        var hPostDil = rawInv.amount - (cnDilutionByInvoice.get(rawInv.id) || 0);
        var hPostCol = rawInv.amount - totalBuyerPaid;
        var hEffBase = Math.max(0, Math.min(rawInv.amount, hPartial, hPostDil, hPostCol));
        var hMaxCap = r2(hEffBase * effectiveAdvanceRate(currentProg, rawInv.supplierId || rawInv.supplierName));
        var hCommitted = (rawInv.capitalDue || 0) + (rawInv.pendingTopUpAmount || 0);
        fundingHeadroom = r2(Math.max(0, hMaxCap - hCommitted));
      }
    }
    var unallocatedPayments = (!isFunded) ? totalBuyerPaid : 0;
    processed.push(Object.assign({}, rawInv, {
      invoiceStatus: statusAsOfDate, invoiceStatusHistory: histAsOfDate,
      fundingStatus: fs, declinedDate: declinedDate, disputedDate: disputedDate,
      penaltyInterest: r2(penBal), penaltyAccrued: r2(penaltyAccrued), interestOutstanding: r2(intBal),
      capitalOutstanding: r2(capBal), holdbackReceived: r2(hbRecd),
      holdbackDisbursed: hbDisbursed, holdbackAvailable: hbAvailable,
      holdbackOutstanding: r2(hbBal), holdbackOverdrawn: holdbackOverdrawn,
      totalOutstanding: r2(intBal + penBal + capBal + Math.max(hbBal, holdbackOverdrawn)),
      balanceOwed: r2(capBal + intBal + penBal + holdbackOverdrawn),
      maxAvailableCapital: r2(maxAvailCap),
      fundingHeadroom: r2(fundingHeadroom),
      unallocatedPayments: r2(unallocatedPayments),
      writeOffTotal: r2(woTotalPen + woTotalInt + woTotalCap + woTotalHb),
      writeOffPenalty: r2(woTotalPen), writeOffInterest: r2(woTotalInt), writeOffCapital: r2(woTotalCap), writeOffHoldback: r2(woTotalHb),
      adjCreditTotal: r2(adjCreditPen + adjCreditInt + adjCreditCap), adjDebitTotal: r2(adjDebitPen + adjDebitInt + adjDebitCap),
      dilutionTotal: r2(cnDilutionByInvoice.get(rawInv.id) || 0),
      amountPostDilutions: r2(rawInv.amount - (cnDilutionByInvoice.get(rawInv.id) || 0)),
      totalFundsApplied: r2(annotatedPays.reduce(function(s, p) { return s + (p.appliedToPenalty || 0) + (p.appliedToInterest || 0) + (p.appliedToCapital || 0) + (p.appliedToHoldback || 0); }, 0)),
      paymentsToInvoice: r2(Math.min(totalBuyerPaid, settleThreshold)),
      settlementThreshold: r2(settleThreshold),
      penaltyDays: penaltyDays, penaltyStartDate: penaltyStartDate, payments: annotatedPays,
      holdbackApplications: hbApplications, holdbackPayments: annotatedHbPays
    }));
  });
  var t = 0, cap = 0, totPen = 0, counts = {};
  processed.forEach(function(inv) {
    t += inv.amount; cap += inv.capitalDue; totPen += inv.penaltyInterest;
    counts[inv.fundingStatus] = (counts[inv.fundingStatus] || 0) + 1;
    counts["inv_" + inv.invoiceStatus] = (counts["inv_" + inv.invoiceStatus] || 0) + 1;
  });
  var mo = {};
  processed.forEach(function(inv) { if (!inv.fundedDate) return; var k = inv.fundedDate.substring(0, 7); mo[k] = (mo[k] || 0) + inv.capitalDue; });
  var chartData = Object.entries(mo).sort(function(a, b) { return a[0].localeCompare(b[0]); }).map(function(e) { return { k: e[0], v: e[1] }; });
  return { invoices: processed, stats: Object.assign({ total: t, capitalAdvanced: cap, totalPenalty: totPen, n: processed.length }, counts), chartData: chartData, cnUnallocBySupplier: cnUnallocBySupplier, cnUnallocByBuyer: cnUnallocByBuyer, cnUnallocBySupBuyer: cnUnallocBySupBuyer };
}


  return {
    // ---- engine entry points ----
    getProgramEligibility: getProgramEligibility,
    getEligiblePrograms: getEligiblePrograms,
    getPurchasablePrograms: getPurchasablePrograms,
    getMaxAvailableCapital: getMaxAvailableCapital,
    effectiveAdvanceRate: effectiveAdvanceRate,
    processForDate: processForDate,
    // ---- the clock ----
    appToday: appToday,
    setAppToday: setAppToday,
    // ---- helpers the browser UI also calls (639 call sites in v6.32) ----
    r2: r2, addDays: addDays, daysBetween: daysBetween,
    parseEntityId: parseEntityId, lowestLimit: lowestLimit, _mk: _mk,
    getSupplierById: getSupplierById, getBranchById: getBranchById,
    getParentEntityId: getParentEntityId,
    getParentSupplierName: getParentSupplierName,
    getParentSupplier: getParentSupplier,
    isEntityPaused: isEntityPaused, isBuyerPaused: isBuyerPaused,
    branchLimitsFor: branchLimitsFor, getSupplierRate: getSupplierRate,
    invoiceTermDays: invoiceTermDays,
    synthesizeTranches: synthesizeTranches,
    tranchesActiveCapital: tranchesActiveCapital,
    tranchesInterestCharged: tranchesInterestCharged,
    tranchesWeightedRate: tranchesWeightedRate,
    applyCapitalRepaymentFIFO: applyCapitalRepaymentFIFO,
    // ---- constant tables ----
    ELIG_REASONS: ELIG_REASONS,
    DEFAULT_PURCHASE_BLOCKED: DEFAULT_PURCHASE_BLOCKED,
    DEFAULT_FUNDING_BLOCKED: DEFAULT_FUNDING_BLOCKED
  };
}
