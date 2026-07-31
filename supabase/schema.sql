-- ===========================================================================
-- Pelagic — public schema
-- Regenerated 31 July 2026 from live introspection queries.
--
-- SCOPE — read this before trusting the file.
--   INCLUDED: all 37 tables, 4 views, primary/foreign keys, check constraints,
--             and all 95 indexes. Reflects state after the 31 July changes
--             (current_invoice_status dropped; dilution limits made nullable;
--             cancelled_date and declined_date added to invoices).
--   ABSENT:   the 31 functions and the 136 RLS policies. Those were read but
--             are not reproduced here, because a partial copy of a function
--             body is worse than none — it invites editing the wrong one.
--
-- This file is therefore a REFERENCE, not a rebuild script. For a complete
-- and authoritative dump, run:
--     supabase db dump --schema public -f supabase/schema.sql
-- and put it in CI so it cannot drift again. The previous file was months
-- stale and had never contained the views at all.
-- ===========================================================================


-- ===========================================================================
-- TABLES
-- ===========================================================================

CREATE TABLE public.audit_log (
  id bigint NOT NULL DEFAULT nextval('audit_log_id_seq'::regclass),
  event_type text NOT NULL,
  details text NOT NULL,
  context jsonb NOT NULL DEFAULT '{}'::jsonb,
  supplier_id text,
  supplier_entity_id text,
  buyer_id text,
  buyer_entity_id text,
  invoice_id text,
  actor text,
  created_at timestamptz NOT NULL DEFAULT now(),
  timestamp timestamptz,          -- duplicate of created_at; see brief
  display_time text               -- formatted copy of the same instant
);

CREATE TABLE public.benchmarks (
  id text NOT NULL,
  name text NOT NULL,
  currency text NOT NULL,
  current_rate numeric NOT NULL DEFAULT 0,
  effective_date date,
  source text NOT NULL DEFAULT 'manual'::text,
  external_id text,
  history jsonb NOT NULL DEFAULT '[]'::jsonb,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.buyer_currency_paid_period (
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  ccy text NOT NULL,
  period_kind character NOT NULL,
  period_key text NOT NULL,
  paid_count integer NOT NULL DEFAULT 0,
  sum_dpd numeric NOT NULL DEFAULT 0,
  on_time_count integer NOT NULL DEFAULT 0,
  bucket_last_paid date,
  sum_days_to_paid numeric,
  sum_stated_term numeric
);

CREATE TABLE public.buyer_currency_weekly (
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  ccy text NOT NULL,
  yw text NOT NULL,
  yr integer NOT NULL,
  invoice_count integer NOT NULL DEFAULT 0,
  total_spend numeric NOT NULL DEFAULT 0,
  cn_count integer NOT NULL DEFAULT 0,
  cn_total numeric NOT NULL DEFAULT 0,
  paid_count_pw integer NOT NULL DEFAULT 0,
  sum_dpd_pw numeric NOT NULL DEFAULT 0,
  on_time_count_pw integer NOT NULL DEFAULT 0,
  dpd_sample_pw integer NOT NULL DEFAULT 0,
  bucket_last_date date,
  short_pay_count integer,
  short_pay_amount numeric,
  sum_days_to_paid_pw numeric,
  sum_stated_term_pw numeric,
  rejected_count integer NOT NULL DEFAULT 0,
  rejected_amount numeric NOT NULL DEFAULT 0,
  cancelled_count integer NOT NULL DEFAULT 0,
  cancelled_amount numeric NOT NULL DEFAULT 0
);

CREATE TABLE public.buyer_doctype_aliases (
  buyer_id text NOT NULL,
  raw_value text NOT NULL,
  sign_bucket text NOT NULL,
  canonical_value text NOT NULL,
  doc_subtype text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  learned_under_provider text,
  last_seen_provider text,
  updated_at timestamptz,
  updated_by uuid,
  classification_note text
);

CREATE TABLE public.buyer_documents (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  doc_class text NOT NULL,
  doc_subtype text,
  raw_document_type text,
  raw_amount numeric NOT NULL,
  sign_bucket text NOT NULL,
  supplier_identifier text NOT NULL,
  supplier_name text,
  buyer_doc_id text,
  supplier_doc_id text,
  partner_doc_id text,
  primary_id_field text NOT NULL DEFAULT 'buyer_doc_id'::text,
  amount numeric NOT NULL,
  paid_amount numeric,
  currency text NOT NULL,
  doc_date date NOT NULL,
  due_date date,
  paid_date date,
  invoice_status text,
  status_change_date date,
  cost_centre text,
  po_number text,
  gl_code text,
  excluded boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.buyer_status_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id text NOT NULL,
  raw_value text NOT NULL,
  canonical_value text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid
);

CREATE TABLE public.buyer_supplier_monthly (
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  ccy text NOT NULL,
  supplier_identifier text NOT NULL,
  supplier_name text,
  ym text NOT NULL,
  yw text,
  yq text,
  yr integer NOT NULL,
  invoice_count integer NOT NULL DEFAULT 0,
  total_spend numeric NOT NULL DEFAULT 0,
  paid_count integer NOT NULL DEFAULT 0,
  unpaid_count integer NOT NULL DEFAULT 0,
  sum_dpd numeric NOT NULL DEFAULT 0,
  dpd_sample_size integer NOT NULL DEFAULT 0,
  on_time_count integer NOT NULL DEFAULT 0,
  late_count integer NOT NULL DEFAULT 0,
  very_late_count integer NOT NULL DEFAULT 0,
  cn_count integer NOT NULL DEFAULT 0,
  cn_total numeric NOT NULL DEFAULT 0,
  first_invoice_in_month date,
  last_invoice_in_month date,
  max_amount numeric NOT NULL DEFAULT 0,
  short_pay_count integer DEFAULT 0,
  short_pay_amount numeric DEFAULT 0,
  settled_count integer DEFAULT 0,
  stale_count integer DEFAULT 0,
  stale_amount numeric DEFAULT 0,
  gl_codes jsonb DEFAULT '[]'::jsonb,
  cost_centres jsonb DEFAULT '[]'::jsonb,
  sum_days_to_paid numeric,
  sum_stated_term numeric,
  stated_term_n integer,
  rejected_count integer,
  rejected_amount numeric,
  term_hist jsonb,
  no_due_count integer,
  no_due_spend numeric,
  outstanding_dollar_days numeric,
  late_1_14_count integer,
  late_15_30_count integer,
  late_31_60_count integer,
  late_61_plus_count integer,
  cancelled_count integer NOT NULL DEFAULT 0,
  cancelled_amount numeric NOT NULL DEFAULT 0,
  mature_invoice_count integer NOT NULL DEFAULT 0,
  mature_resolved_count integer NOT NULL DEFAULT 0
);

CREATE TABLE public.buyer_upload_snapshots (
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  schema_version integer NOT NULL DEFAULT 1,
  stats jsonb NOT NULL,
  computed_at timestamptz NOT NULL DEFAULT now(),
  invoice_count integer NOT NULL,
  cn_count integer NOT NULL,
  computed_in_ms integer
);

CREATE TABLE public.buyer_upload_supplier_counts (
  buyer_id text NOT NULL,
  upload_id uuid NOT NULL,
  supplier_identifier text NOT NULL,
  cnt bigint NOT NULL
);

CREATE TABLE public.buyer_uploads (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_label text NOT NULL,
  notes text,
  invoice_file_name text,
  cn_file_name text,
  currencies_seen text[] DEFAULT '{}'::text[],
  invoice_count integer DEFAULT 0,
  cn_count integer DEFAULT 0,
  supplier_count integer DEFAULT 0,
  date_range_min date,
  date_range_max date,
  created_at timestamptz DEFAULT now(),
  created_by text,
  buyer_id text,
  snapshot_status text NOT NULL DEFAULT 'pending'::text,
  snapshot_error text,
  snapshot_started_at timestamptz,
  snapshot_finished_at timestamptz
);

CREATE TABLE public.buyers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text, street2 text, city text, state text, zip text, country text,
  company_number text,
  vat_number text,
  branches jsonb NOT NULL DEFAULT '[]'::jsonb,
  credit_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  single_invoice_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  onboarding_date date,
  paused boolean NOT NULL DEFAULT false,
  primary_contact text, primary_email text, primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text, secondary_email text, secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text, contact3_email text, contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text, contact4_email text, contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text, contact5_email text, contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamptz,
  entity_files jsonb NOT NULL DEFAULT '[]'::jsonb,
  kyc jsonb NOT NULL DEFAULT '{"passed": false}'::jsonb,
  supplier_outreach_permitted boolean NOT NULL DEFAULT false,
  program_paused jsonb DEFAULT '{}'::jsonb,
  verification_source text,
  ch_verification text,
  remittance_sla_days integer DEFAULT 5,
  program_rates jsonb DEFAULT '{}'::jsonb
);

CREATE TABLE public.credit_notes (
  credit_note_id text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date NOT NULL,                 -- bare "date"; see brief
  reference text,
  supplier_id text NOT NULL,
  supplier_entity_id text,
  buyer_id text NOT NULL,
  buyer_entity_id text,
  allocations jsonb NOT NULL DEFAULT '[]'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  voided boolean NOT NULL DEFAULT false,
  voided_at timestamptz,
  voided_by text,
  void_reason text,
  created_display text,
  created_at timestamptz NOT NULL DEFAULT now(),
  raw_document_type text,
  raw_amount numeric,
  doc_subtype text,
  source_provider text,
  sign_bucket text,
  import_batch text,
  reclassified_from_type text,
  reclassified_from_id text,
  reclassified_at timestamptz,
  reclassified_by uuid,
  supplier_name text,
  buyer_name text
);

CREATE TABLE public.csv_providers (
  provider_id text NOT NULL,
  provider_name text NOT NULL,
  provider_kind text NOT NULL,
  associated_buyer_id text,
  associated_supplier_id text,
  status text NOT NULL DEFAULT 'active'::text,
  superseded_by_provider_id text,
  superseded_at timestamptz,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.csv_review_queue (
  id text NOT NULL DEFAULT (gen_random_uuid())::text,
  status text NOT NULL DEFAULT 'pending'::text,
  payload jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  invoice_id text,
  invoice_reference text,
  field_name text,
  field_label text,
  old_value text,
  new_value text,
  csv_row jsonb,
  resolved_at text               -- text, not timestamptz; see brief
);

CREATE TABLE public.daily_book_snapshots (
  id bigint NOT NULL DEFAULT nextval('daily_book_snapshots_id_seq'::regclass),
  snapshot_date date NOT NULL,
  invoice_id text NOT NULL,
  capital_outstanding numeric,       -- never populated; see brief
  interest_outstanding numeric,      -- never populated
  penalty_outstanding numeric,       -- never populated
  holdback_outstanding numeric,
  penalty_accrued numeric,
  tranche_state jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  funding_program text,
  supplier_id text,
  supplier_entity_id text,
  buyer_id text,
  buyer_entity_id text,
  currency text,
  funding_status text,
  invoice_status text,
  invoice_status_history jsonb,
  approved_date date,
  invoice_date date,
  due_date date,
  funded_date date,
  fully_repaid_date date,
  settled_date date,
  disputed_date date,
  days_overdue integer,
  amount numeric,
  capital_due numeric,
  interest_charged numeric,
  partial_approved_amount numeric,
  amount_post_dilutions numeric,     -- never populated
  holdback numeric,
  holdback_overdrawn numeric,
  debt_balance numeric,              -- never populated
  balance_owed numeric,              -- never populated
  advance_rate numeric,
  annual_rate numeric,
  penalty_rate numeric,
  pending_top_up_amount numeric,
  pending_top_up_date date,
  pending_top_up_rate numeric,
  do_not_advance boolean,
  do_not_purchase boolean,
  voided boolean,
  void_reason text,
  voided_at timestamptz,
  buyer_ref text,
  supplier_ref text,
  invoice_reference text,
  written_at timestamptz,
  is_backfilled boolean NOT NULL DEFAULT false,
  pending_doctype_confirmation boolean
);

CREATE TABLE public.disregarded_documents (
  id bigint NOT NULL DEFAULT nextval('disregarded_documents_id_seq'::regclass),
  buyer_id text NOT NULL,
  buyer_entity_id text,
  supplier_id text,
  supplier_entity_id text,
  reference text,
  currency text,
  doc_date date,
  amount numeric NOT NULL,
  raw_document_type text,
  raw_amount numeric,
  sign_bucket text,
  doc_subtype text,
  source_provider text,
  import_batch text,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  reclassified_from_type text,
  reclassified_from_id text,
  reclassified_at timestamptz,
  reclassified_by uuid
);

CREATE TABLE public.entity_aliases (
  id bigint NOT NULL DEFAULT nextval('entity_aliases_id_seq'::regclass),
  alias_name text NOT NULL,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  entity_name text
);

CREATE TABLE public.entity_notes (
  id text NOT NULL,
  entity_id text NOT NULL,
  entity_type text NOT NULL,
  text text NOT NULL,
  author text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.funding_programs (
  id text NOT NULL,
  name text NOT NULL,
  currency text NOT NULL,
  max_size numeric NOT NULL DEFAULT 0,
  current_funded_balance numeric NOT NULL DEFAULT 0,
  max_advance_rate numeric NOT NULL DEFAULT 0.9,
  min_interest_rate numeric NOT NULL DEFAULT 0.15,
  max_invoice_term integer NOT NULL DEFAULT 90,
  min_invoice_tenor integer NOT NULL DEFAULT 0,
  min_invoice_size numeric NOT NULL DEFAULT 0,
  threshold_overdue integer NOT NULL DEFAULT 1,
  threshold_at_risk integer NOT NULL DEFAULT 7,
  threshold_recovery integer NOT NULL DEFAULT 30,
  threshold_dispute_at_risk integer NOT NULL DEFAULT 1,
  threshold_dispute_recovery integer NOT NULL DEFAULT 14,
  -- Nullable since 31 July 2026: NULL means no limit, 0 means zero tolerance.
  -- Previously NOT NULL DEFAULT 0, which made the two indistinguishable.
  max_sup_dil_live numeric,
  max_sup_dil_30 numeric,
  max_sup_dil_90 numeric,
  max_fund_dil_live numeric,
  max_fund_dil_30 numeric,
  max_fund_dil_90 numeric,
  eligible_suppliers jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_buyers jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_buyer_jurisdictions jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_supplier_jurisdictions jsonb NOT NULL DEFAULT '[]'::jsonb,
  fund_flows jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  benchmark text,
  threshold_deemed integer DEFAULT 60,
  penalty_multiplier numeric DEFAULT 1.5,
  day_count integer DEFAULT 360,
  penalty_grace_days integer DEFAULT 0,
  min_rate jsonb DEFAULT '[]'::jsonb,
  dynamic_limit jsonb
);

CREATE TABLE public.holdback_payment_allocations (
  id bigint NOT NULL DEFAULT nextval('holdback_payment_allocations_id_seq'::regclass),
  hb_payment_id text NOT NULL,
  type text NOT NULL,
  target_id text,
  amount numeric NOT NULL,
  supplier_id text,
  supplier_entity_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.holdback_payments (
  hb_payment_id text NOT NULL,
  source_invoice_id text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date NOT NULL,                -- bare "date"; see brief
  supplier_id text,
  supplier_entity_id text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.invoices (
  id text NOT NULL,                        -- Pelagic Invoice Ref (canonical)
  supplier_id text NOT NULL,
  supplier_entity_id text,
  buyer_id text NOT NULL,
  buyer_entity_id text,
  amount numeric NOT NULL,
  currency text NOT NULL,
  invoice_date date NOT NULL,
  due_date date NOT NULL,
  buyer_ref text,                          -- Buyer Invoice Ref
  supplier_ref text,                       -- Supplier Invoice Ref
  purchase_order text,
  invoice_reference text,                  -- 3rd Party ID (rename pending)
  buyer_received_date date,
  invoice_status text NOT NULL DEFAULT 'Received'::text,
  funding_status text NOT NULL DEFAULT 'pending'::text,
  invoice_status_history jsonb NOT NULL DEFAULT '[]'::jsonb,
  disputed_date date,
  cancelled_date date,                     -- added 31 July 2026
  declined_date date,                      -- added 31 July 2026
  funding_program text,
  approved_date date,
  funded_date date,
  fully_repaid_date date,
  settled_date date,
  partial_approved_amount numeric NOT NULL DEFAULT 0,
  capital_due numeric NOT NULL DEFAULT 0,
  holdback numeric NOT NULL DEFAULT 0,
  interest_charged numeric NOT NULL DEFAULT 0,
  deferred_payment numeric NOT NULL DEFAULT 0,
  days_to_maturity integer NOT NULL DEFAULT 0,
  advance_rate numeric NOT NULL DEFAULT 0,
  annual_rate numeric NOT NULL DEFAULT 0,
  penalty_rate numeric NOT NULL DEFAULT 0,
  tranches jsonb NOT NULL DEFAULT '[]'::jsonb,
  pending_top_up_amount numeric NOT NULL DEFAULT 0,
  pending_top_up_rate numeric,
  pending_top_up_date date,
  do_not_purchase boolean NOT NULL DEFAULT false,
  do_not_advance boolean NOT NULL DEFAULT false,
  voided boolean NOT NULL DEFAULT false,
  voided_at timestamptz,
  voided_by text,
  void_reason text,
  adjustments jsonb NOT NULL DEFAULT '[]'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  -- The five below are computed by processForDate(viewDate) in the browser
  -- and are never written. See brief: they are date-relative projections,
  -- and the cron and snapshot both depend on them.
  capital_outstanding numeric,
  interest_outstanding numeric,
  penalty_outstanding numeric,
  holdback_outstanding numeric,
  holdback_overdrawn numeric,
  debt_balance numeric,
  balance_owed numeric,
  amount_post_dilutions numeric,
  created_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  written_down_short boolean DEFAULT false,
  write_down_date date,
  -- BI ingestion vocabulary. Unused by the Dashboard; all NULL/false.
  pending_doctype_confirmation boolean NOT NULL DEFAULT false,
  raw_document_type text,
  raw_amount numeric,
  source_provider text,
  sign_bucket text,
  import_batch text,
  reclassified_to_type text,
  reclassified_to_id text,
  reclassified_at timestamptz,
  reclassified_by uuid,
  supplier_name text,
  buyer_name text
);

CREATE TABLE public.payment_allocations (
  id bigint NOT NULL DEFAULT nextval('payment_allocations_id_seq'::regclass),
  payment_id text NOT NULL,
  invoice_id text NOT NULL,
  amount numeric NOT NULL,
  alloc_date date,
  supplier_id text,
  supplier_entity_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  kind text NOT NULL DEFAULT 'funded_recovery'::text
);

CREATE TABLE public.payments (
  payment_id text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date NOT NULL,                -- bare "date"; see brief
  reference text,
  direction text NOT NULL DEFAULT 'inbound'::text,
  buyer_id text,
  buyer_entity_id text,
  supplier_id text,
  supplier_entity_id text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  source text DEFAULT 'buyer'::text
);

CREATE TABLE public.prospect_groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  legal_name text NOT NULL,
  registry_id text NOT NULL,
  verification_source text,
  verification_jurisdiction text,
  verification_data jsonb,
  converted_supplier_id text,
  converted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.prospect_notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  prospect_supplier_id uuid NOT NULL,
  content text NOT NULL,
  note_type text NOT NULL DEFAULT 'user'::text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.prospect_suppliers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id text NOT NULL,
  supplier_identifier text NOT NULL,
  currency text NOT NULL,
  status text NOT NULL DEFAULT 'lead'::text,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  registry_id text,
  legal_name text,
  verified_at timestamptz,
  contact_name text,
  contact_email text,
  contact_phone text,
  converted_supplier_id text,
  converted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  supplier_name text,
  next_action_at timestamptz,
  next_action_note text,
  verification_source text,
  verification_jurisdiction text,
  verified_by uuid,
  verification_notes text,
  verification_raw jsonb,
  group_id uuid,
  branch_decision text DEFAULT 'unassigned'::text,
  converted_branch_id text,
  branch_decision_at timestamptz,
  branch_decision_by uuid
);

CREATE TABLE public.provider_entity_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  provider_id text,
  entity_type text NOT NULL,
  external_string text NOT NULL,
  pelagic_entity_id text NOT NULL,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  first_seen_in_upload_id text,
  verified_by text,
  verified_at timestamptz,
  notes text,
  buyer_entity_id text
);

CREATE TABLE public.rate_recompute_queue (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  triggered_by text NOT NULL,
  benchmark_id text,
  trigger_entity_id text,
  trigger_program_id text,
  triggered_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending'::text,
  affected_count integer,
  completed_at timestamptz,
  error text
);

CREATE TABLE public.service_providers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text, street2 text, city text, state text, zip text, country text,
  company_number text,
  vat_number text,
  bank_name text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  role text,
  onboarding_date date,
  account_name text, sort_code text, account_number text, iban text, bic text,
  primary_contact text, primary_email text, primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text, secondary_email text, secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text, contact3_email text, contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text, contact4_email text, contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text, contact5_email text, contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  paused boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamptz,
  entity_files jsonb NOT NULL DEFAULT '[]'::jsonb,
  kyc jsonb NOT NULL DEFAULT '{"passed": false}'::jsonb,
  verification_source text,
  ch_verification text
);

CREATE TABLE public.supplier_backfill (
  supplier_entity_id text NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text,
  range_from date,
  range_to date,
  ready_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.supplier_payment_queue (
  id text NOT NULL,
  type text NOT NULL,
  status text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date,                          -- bare "date"; see brief
  supplier_id text NOT NULL,
  supplier_entity_id text,
  invoice_id text,
  invoice_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  source_invoice_id text,
  source_payment_id text,
  funding_program text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  supplier_name text,
  bank_name text,
  bank_details text,
  program_id text,
  program_name text,
  created_display text,
  executed_at text,                   -- text, not timestamptz; see brief
  executed_display text,
  hb_payment_id text,
  is_bundle boolean NOT NULL DEFAULT false,
  holdback_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  gross_amount numeric,
  deductions jsonb NOT NULL DEFAULT '[]'::jsonb,
  deduction_total numeric NOT NULL DEFAULT 0,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  cancelled_at text,                  -- text, not timestamptz
  cancelled_display text,
  failed_at text,                     -- text, not timestamptz
  failed_display text
);

CREATE TABLE public.supplier_program_buyer_limit (
  funding_program text NOT NULL,
  supplier_entity_id text NOT NULL,
  buyer_entity_id text NOT NULL,
  currency text,
  avg_outstanding_60d numeric DEFAULT 0,
  sample_days integer DEFAULT 0,
  multiple numeric,
  computed_limit numeric,
  ceiling numeric,
  limit_value numeric,
  window_from date,
  window_to date,
  computed_at timestamptz NOT NULL DEFAULT now(),
  avg_invoice_size_60d numeric,
  invoice_sample_count integer,
  invoice_multiple numeric,
  computed_invoice_limit numeric,
  invoice_ceiling numeric,
  invoice_limit_value numeric
);

CREATE TABLE public.supplier_program_buyer_override (
  funding_program text NOT NULL,
  supplier_entity_id text NOT NULL,
  buyer_entity_id text NOT NULL,
  override_value numeric NOT NULL,
  note text,
  set_by text,
  updated_at timestamptz NOT NULL DEFAULT now(),
  invoice_override_value numeric
);

CREATE TABLE public.suppliers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text, street2 text, city text, state text, zip text, country text,
  company_number text,
  vat_number text,
  bank_name text,
  bank_verified boolean NOT NULL DEFAULT false,
  branches jsonb NOT NULL DEFAULT '[]'::jsonb,
  program_rates jsonb NOT NULL DEFAULT '{}'::jsonb,
  credit_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  single_invoice_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  program_bank_accounts jsonb NOT NULL DEFAULT '{}'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  onboarding_date date,
  paused boolean NOT NULL DEFAULT false,
  rates jsonb NOT NULL DEFAULT '[]'::jsonb,
  account_name text, sort_code text, account_number text, iban text, bic text,
  primary_contact text, primary_email text, primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text, secondary_email text, secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text, contact3_email text, contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text, contact4_email text, contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text, contact5_email text, contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamptz,
  entity_files jsonb NOT NULL DEFAULT '[]'::jsonb,
  kyc jsonb NOT NULL DEFAULT '{"passed": false}'::jsonb,
  program_paused jsonb DEFAULT '{}'::jsonb,
  verification_source text,
  ch_verification text,
  limits_confirmed jsonb NOT NULL DEFAULT '{}'::jsonb,
  min_settled_overrides jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE public.user_profiles (
  id uuid NOT NULL,
  email text NOT NULL,
  full_name text,
  role text NOT NULL,             -- no CHECK constraint; see brief
  supplier_id text,
  is_active boolean DEFAULT true,
  last_login_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  status text DEFAULT 'active'::text,
  buyer_id text,
  branch_id text
);


-- ===========================================================================
-- PRIMARY KEYS
-- ===========================================================================
ALTER TABLE public.audit_log                       ADD PRIMARY KEY (id);
ALTER TABLE public.benchmarks                      ADD PRIMARY KEY (id);
ALTER TABLE public.buyer_currency_paid_period      ADD PRIMARY KEY (upload_id, ccy, period_kind, period_key);
ALTER TABLE public.buyer_currency_weekly           ADD PRIMARY KEY (upload_id, ccy, yw);
ALTER TABLE public.buyer_doctype_aliases           ADD PRIMARY KEY (buyer_id, raw_value, sign_bucket);
ALTER TABLE public.buyer_documents                 ADD PRIMARY KEY (id);
ALTER TABLE public.buyer_status_aliases            ADD PRIMARY KEY (id);
ALTER TABLE public.buyer_supplier_monthly          ADD PRIMARY KEY (upload_id, ccy, supplier_identifier, ym);
ALTER TABLE public.buyer_upload_snapshots          ADD PRIMARY KEY (upload_id);
ALTER TABLE public.buyer_upload_supplier_counts    ADD PRIMARY KEY (buyer_id, upload_id, supplier_identifier);
ALTER TABLE public.buyer_uploads                   ADD PRIMARY KEY (id);
ALTER TABLE public.buyers                          ADD PRIMARY KEY (id);
ALTER TABLE public.credit_notes                    ADD PRIMARY KEY (credit_note_id);
ALTER TABLE public.csv_providers                   ADD PRIMARY KEY (provider_id);
ALTER TABLE public.csv_review_queue                ADD PRIMARY KEY (id);
ALTER TABLE public.daily_book_snapshots            ADD PRIMARY KEY (id);
ALTER TABLE public.disregarded_documents           ADD PRIMARY KEY (id);
ALTER TABLE public.entity_aliases                  ADD PRIMARY KEY (id);
ALTER TABLE public.entity_notes                    ADD PRIMARY KEY (id);
ALTER TABLE public.funding_programs                ADD PRIMARY KEY (id);
ALTER TABLE public.holdback_payment_allocations    ADD PRIMARY KEY (id);
ALTER TABLE public.holdback_payments               ADD PRIMARY KEY (hb_payment_id);
ALTER TABLE public.invoices                        ADD PRIMARY KEY (id);
ALTER TABLE public.payment_allocations             ADD PRIMARY KEY (id);
ALTER TABLE public.payments                        ADD PRIMARY KEY (payment_id);
ALTER TABLE public.prospect_groups                 ADD PRIMARY KEY (id);
ALTER TABLE public.prospect_notes                  ADD PRIMARY KEY (id);
ALTER TABLE public.prospect_suppliers              ADD PRIMARY KEY (id);
ALTER TABLE public.provider_entity_aliases         ADD PRIMARY KEY (id);
ALTER TABLE public.rate_recompute_queue            ADD PRIMARY KEY (id);
ALTER TABLE public.service_providers               ADD PRIMARY KEY (id);
ALTER TABLE public.supplier_backfill               ADD PRIMARY KEY (supplier_entity_id);
ALTER TABLE public.supplier_payment_queue          ADD PRIMARY KEY (id);
ALTER TABLE public.supplier_program_buyer_limit    ADD PRIMARY KEY (funding_program, supplier_entity_id, buyer_entity_id);
ALTER TABLE public.supplier_program_buyer_override ADD PRIMARY KEY (funding_program, supplier_entity_id, buyer_entity_id);
ALTER TABLE public.suppliers                       ADD PRIMARY KEY (id);
ALTER TABLE public.user_profiles                   ADD PRIMARY KEY (id);


-- ===========================================================================
-- UNIQUE CONSTRAINTS
-- ===========================================================================
ALTER TABLE public.buyers               ADD UNIQUE (company_number);
ALTER TABLE public.suppliers            ADD UNIQUE (company_number);
ALTER TABLE public.buyer_status_aliases ADD UNIQUE (buyer_id, raw_value);
ALTER TABLE public.daily_book_snapshots ADD UNIQUE (snapshot_date, invoice_id);
ALTER TABLE public.prospect_groups      ADD UNIQUE (registry_id);
ALTER TABLE public.prospect_suppliers   ADD UNIQUE (buyer_id, supplier_identifier, currency);
-- NOTE: invoices has NO unique constraint on any reference column. The
-- primary key on id is the only uniqueness in the table. See brief.


-- ===========================================================================
-- FOREIGN KEYS
-- ===========================================================================
ALTER TABLE public.buyer_currency_paid_period   ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.buyer_currency_paid_period   ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_currency_weekly        ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.buyer_currency_weekly        ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_doctype_aliases        ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_documents              ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id);
ALTER TABLE public.buyer_documents              ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_status_aliases         ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_status_aliases         ADD FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE public.buyer_supplier_monthly       ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.buyer_supplier_monthly       ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_upload_snapshots       ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.buyer_upload_snapshots       ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_upload_supplier_counts ADD FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;
ALTER TABLE public.buyer_uploads                ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.credit_notes                 ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id);
ALTER TABLE public.credit_notes                 ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.csv_providers                ADD FOREIGN KEY (associated_buyer_id) REFERENCES buyers(id);
ALTER TABLE public.csv_providers                ADD FOREIGN KEY (associated_supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.csv_providers                ADD FOREIGN KEY (superseded_by_provider_id) REFERENCES csv_providers(provider_id);
ALTER TABLE public.daily_book_snapshots         ADD FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;
ALTER TABLE public.disregarded_documents        ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;
ALTER TABLE public.disregarded_documents        ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;
ALTER TABLE public.holdback_payment_allocations ADD FOREIGN KEY (hb_payment_id) REFERENCES holdback_payments(hb_payment_id) ON DELETE CASCADE;
ALTER TABLE public.holdback_payment_allocations ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.holdback_payments            ADD FOREIGN KEY (source_invoice_id) REFERENCES invoices(id);
ALTER TABLE public.holdback_payments            ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.invoices                     ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id);
ALTER TABLE public.invoices                     ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.invoices                     ADD FOREIGN KEY (funding_program) REFERENCES funding_programs(id);
ALTER TABLE public.payment_allocations          ADD FOREIGN KEY (invoice_id) REFERENCES invoices(id);
ALTER TABLE public.payment_allocations          ADD FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE;
ALTER TABLE public.payment_allocations          ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.payments                     ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id);
ALTER TABLE public.payments                     ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.prospect_notes               ADD FOREIGN KEY (created_by) REFERENCES auth.users(id);
ALTER TABLE public.prospect_notes               ADD FOREIGN KEY (prospect_supplier_id) REFERENCES prospect_suppliers(id) ON DELETE CASCADE;
ALTER TABLE public.prospect_suppliers           ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;
ALTER TABLE public.prospect_suppliers           ADD FOREIGN KEY (group_id) REFERENCES prospect_groups(id) ON DELETE SET NULL;
ALTER TABLE public.prospect_suppliers           ADD FOREIGN KEY (verified_by) REFERENCES auth.users(id);
ALTER TABLE public.provider_entity_aliases      ADD FOREIGN KEY (provider_id) REFERENCES csv_providers(provider_id);
ALTER TABLE public.supplier_payment_queue       ADD FOREIGN KEY (invoice_id) REFERENCES invoices(id);
ALTER TABLE public.supplier_payment_queue       ADD FOREIGN KEY (supplier_id) REFERENCES suppliers(id);
ALTER TABLE public.supplier_payment_queue       ADD FOREIGN KEY (funding_program) REFERENCES funding_programs(id);
ALTER TABLE public.user_profiles                ADD FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.user_profiles                ADD FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;


-- ===========================================================================
-- CHECK CONSTRAINTS
-- ===========================================================================
ALTER TABLE public.buyer_doctype_aliases ADD CHECK (raw_value = lower(btrim(raw_value)));
ALTER TABLE public.buyer_doctype_aliases ADD CHECK (canonical_value = ANY (ARRAY['invoice','credit_note','disregard']));
ALTER TABLE public.buyer_doctype_aliases ADD CHECK (sign_bucket = ANY (ARRAY['positive','negative']));
ALTER TABLE public.buyer_documents       ADD CHECK (doc_class <> 'credit_note' OR invoice_status IS NULL);
ALTER TABLE public.buyer_documents       ADD CHECK (doc_class <> 'credit_note' OR due_date IS NULL);
ALTER TABLE public.buyer_documents       ADD CHECK (doc_class = ANY (ARRAY['invoice','credit_note','disregard']));
ALTER TABLE public.buyer_documents       ADD CHECK (invoice_status = ANY (ARRAY['paid','cancelled','rejected','approved','processing']));
ALTER TABLE public.buyer_documents       ADD CHECK (amount >= 0::numeric);
ALTER TABLE public.buyer_status_aliases  ADD CHECK (canonical_value = ANY (ARRAY['paid','cancelled','rejected','approved','processing']));
ALTER TABLE public.credit_notes          ADD CHECK (reclassified_from_type IS NULL OR reclassified_from_type = ANY (ARRAY['invoice','disregard']));
ALTER TABLE public.csv_providers         ADD CHECK (provider_kind = ANY (ARRAY['platform','buyer_direct','supplier_direct','other']));
ALTER TABLE public.csv_providers         ADD CHECK (status = ANY (ARRAY['active','superseded']));
ALTER TABLE public.csv_providers         ADD CHECK (
     (status = 'active'    AND superseded_by_provider_id IS NULL     AND superseded_at IS NULL)
  OR (status = 'superseded' AND superseded_by_provider_id IS NOT NULL AND superseded_at IS NOT NULL));
ALTER TABLE public.csv_providers         ADD CHECK (
     (provider_kind = 'buyer_direct'    AND associated_buyer_id IS NOT NULL AND associated_supplier_id IS NULL)
  OR (provider_kind = 'supplier_direct' AND associated_supplier_id IS NOT NULL AND associated_buyer_id IS NULL)
  OR (provider_kind = 'platform'        AND associated_buyer_id IS NULL AND associated_supplier_id IS NULL)
  OR (provider_kind = 'other'));
ALTER TABLE public.disregarded_documents ADD CHECK (amount >= 0::numeric);
ALTER TABLE public.invoices              ADD CHECK (reclassified_to_type IS NULL OR reclassified_to_type = ANY (ARRAY['credit_note','disregard']));
ALTER TABLE public.payment_allocations   ADD CHECK (kind = ANY (ARRAY['funded_recovery','pass_through']));
ALTER TABLE public.prospect_notes        ADD CHECK (note_type = ANY (ARRAY['user','system']));
ALTER TABLE public.prospect_suppliers    ADD CHECK (status = ANY (ARRAY['lead','contacted','interested','negotiating','onboarding','converted','declined']));
ALTER TABLE public.prospect_suppliers    ADD CHECK (branch_decision = ANY (ARRAY['unassigned','parent_main','branch','skip']));
ALTER TABLE public.prospect_suppliers    ADD CHECK (verification_source IS NULL OR verification_source = ANY (ARRAY['companies_house','manual','other']));
ALTER TABLE public.provider_entity_aliases ADD CHECK (entity_type = ANY (ARRAY['supplier','buyer']));
ALTER TABLE public.provider_entity_aliases ADD CHECK (entity_type <> 'buyer' OR provider_id IS NOT NULL);
-- NOTE: invoices.invoice_status and user_profiles.role have NO check
-- constraint. Both should. See brief.


-- ===========================================================================
-- INDEXES (non-constraint)
-- ===========================================================================
CREATE INDEX idx_audit_buyer_id            ON public.audit_log (buyer_id);
CREATE INDEX idx_audit_created_at          ON public.audit_log (created_at);
CREATE INDEX idx_audit_invoice_id          ON public.audit_log (invoice_id);
CREATE INDEX idx_audit_supplier_entity_id  ON public.audit_log (supplier_entity_id);
CREATE INDEX idx_audit_supplier_id         ON public.audit_log (supplier_id);
CREATE INDEX buyer_currency_paid_period_ccy_period_idx ON public.buyer_currency_paid_period (upload_id, ccy, period_kind);
CREATE INDEX bcw_upload_ccy_idx            ON public.buyer_currency_weekly (upload_id, ccy);
CREATE INDEX bcw_upload_idx                ON public.buyer_currency_weekly (upload_id);
CREATE INDEX bcw_upload_yr_idx             ON public.buyer_currency_weekly (upload_id, yr);
CREATE INDEX idx_bd_buyer_ccy              ON public.buyer_documents (buyer_id, currency, doc_class);
CREATE INDEX idx_bd_buyer_sup              ON public.buyer_documents (buyer_id, supplier_identifier);
CREATE INDEX idx_bd_reclass                ON public.buyer_documents (buyer_id, raw_document_type, sign_bucket);
CREATE INDEX idx_bd_upload_class           ON public.buyer_documents (upload_id, doc_class) WHERE (NOT excluded);
CREATE INDEX bsm_upload_ccy_idx            ON public.buyer_supplier_monthly (upload_id, ccy);
CREATE INDEX bsm_upload_idx                ON public.buyer_supplier_monthly (upload_id);
CREATE INDEX bsm_upload_yr_idx             ON public.buyer_supplier_monthly (upload_id, yr);
CREATE INDEX bi_snapshots_buyer_idx        ON public.buyer_upload_snapshots (buyer_id);
CREATE INDEX idx_buyer_uploads_created_at  ON public.buyer_uploads (created_at DESC);
CREATE UNIQUE INDEX buyers_registry_uq     ON public.buyers (COALESCE(verification_source,'companies_house'), company_number) WHERE (company_number IS NOT NULL);
CREATE INDEX idx_buyers_name               ON public.buyers (name);
CREATE INDEX credit_notes_import_batch_idx ON public.credit_notes (import_batch) WHERE (import_batch IS NOT NULL);
CREATE INDEX idx_cn_buyer_id               ON public.credit_notes (buyer_id);
CREATE INDEX idx_cn_supplier_entity_id     ON public.credit_notes (supplier_entity_id);
CREATE INDEX idx_cn_supplier_id            ON public.credit_notes (supplier_id);
CREATE INDEX csv_providers_status_idx      ON public.csv_providers (status) WHERE (status = 'active');
CREATE INDEX idx_csv_status                ON public.csv_review_queue (status);
CREATE INDEX daily_book_snapshots_backfilled_idx      ON public.daily_book_snapshots (is_backfilled);
CREATE INDEX daily_book_snapshots_date_idx            ON public.daily_book_snapshots (snapshot_date);
CREATE UNIQUE INDEX daily_book_snapshots_invoice_date_uniq ON public.daily_book_snapshots (invoice_id, snapshot_date);
CREATE INDEX daily_book_snapshots_sup_prog_date_idx    ON public.daily_book_snapshots (supplier_id, funding_program, snapshot_date);
CREATE INDEX daily_book_snapshots_supent_prog_date_idx ON public.daily_book_snapshots (supplier_entity_id, funding_program, snapshot_date);
CREATE INDEX idx_snapshots_date             ON public.daily_book_snapshots (snapshot_date);
CREATE INDEX disregarded_documents_batch_idx ON public.disregarded_documents (import_batch);
CREATE INDEX disregarded_documents_buyer_idx ON public.disregarded_documents (buyer_id);
CREATE INDEX idx_aliases_lookup             ON public.entity_aliases (entity_type, alias_name);
CREATE INDEX idx_entity_notes_entity        ON public.entity_notes (entity_type, entity_id);
CREATE INDEX idx_hba_hb_payment_id          ON public.holdback_payment_allocations (hb_payment_id);
CREATE INDEX idx_hba_supplier_id            ON public.holdback_payment_allocations (supplier_id);
CREATE INDEX idx_hbp_source_invoice         ON public.holdback_payments (source_invoice_id);
CREATE INDEX idx_hbp_supplier_id            ON public.holdback_payments (supplier_id);
CREATE INDEX idx_invoices_buyer_entity_id   ON public.invoices (buyer_entity_id);
CREATE INDEX idx_invoices_buyer_id          ON public.invoices (buyer_id);
CREATE INDEX idx_invoices_funding_program   ON public.invoices (funding_program);
CREATE INDEX idx_invoices_funding_status    ON public.invoices (funding_status);
CREATE INDEX idx_invoices_supplier_entity_id ON public.invoices (supplier_entity_id);
CREATE INDEX idx_invoices_supplier_id       ON public.invoices (supplier_id);
CREATE INDEX invoices_import_batch_idx      ON public.invoices (import_batch) WHERE (import_batch IS NOT NULL);
CREATE INDEX invoices_pending_doctype_idx   ON public.invoices (buyer_id) WHERE pending_doctype_confirmation;
CREATE INDEX idx_pa_invoice_id              ON public.payment_allocations (invoice_id);
CREATE INDEX idx_pa_payment_id              ON public.payment_allocations (payment_id);
CREATE INDEX idx_pa_supplier_entity_id      ON public.payment_allocations (supplier_entity_id);
CREATE INDEX idx_pa_supplier_id             ON public.payment_allocations (supplier_id);
CREATE INDEX payment_allocations_kind_idx   ON public.payment_allocations (kind);
CREATE INDEX idx_payments_buyer_id          ON public.payments (buyer_id);
CREATE INDEX idx_payments_date              ON public.payments (date);
CREATE INDEX idx_payments_supplier_id       ON public.payments (supplier_id);
CREATE INDEX idx_prospect_groups_converted_supplier_id ON public.prospect_groups (converted_supplier_id) WHERE (converted_supplier_id IS NOT NULL);
CREATE INDEX idx_prospect_groups_registry_id ON public.prospect_groups (registry_id);
CREATE UNIQUE INDEX prospect_groups_registry_id_unique ON public.prospect_groups (registry_id);
CREATE INDEX prospect_notes_supplier_idx    ON public.prospect_notes (prospect_supplier_id, created_at DESC);
CREATE INDEX idx_prospect_suppliers_group_id ON public.prospect_suppliers (group_id) WHERE (group_id IS NOT NULL);
CREATE INDEX prospect_suppliers_buyer_idx   ON public.prospect_suppliers (buyer_id);
CREATE INDEX prospect_suppliers_cross_buyer_idx ON public.prospect_suppliers (verification_jurisdiction, registry_id) WHERE (registry_id IS NOT NULL AND verified_at IS NOT NULL);
CREATE INDEX prospect_suppliers_last_seen_idx ON public.prospect_suppliers (last_seen_at DESC);
CREATE INDEX prospect_suppliers_next_action_idx ON public.prospect_suppliers (next_action_at) WHERE (next_action_at IS NOT NULL AND status <> ALL (ARRAY['converted','declined']));
CREATE INDEX prospect_suppliers_registry_idx ON public.prospect_suppliers (registry_id) WHERE (registry_id IS NOT NULL);
CREATE INDEX prospect_suppliers_status_idx  ON public.prospect_suppliers (status) WHERE (status <> ALL (ARRAY['converted','declined']));
CREATE UNIQUE INDEX pea_buyer_uq            ON public.provider_entity_aliases (provider_id, external_string) WHERE (entity_type = 'buyer');
CREATE UNIQUE INDEX pea_supplier_uq         ON public.provider_entity_aliases (buyer_entity_id, external_string) WHERE (entity_type = 'supplier' AND buyer_entity_id IS NOT NULL);
CREATE INDEX provider_entity_aliases_pelagic_idx ON public.provider_entity_aliases (pelagic_entity_id, entity_type);
CREATE INDEX rate_recompute_queue_status_triggered_at_idx ON public.rate_recompute_queue (status, triggered_at) WHERE (status = ANY (ARRAY['pending','running']));
CREATE INDEX idx_spq_source_payment_id      ON public.supplier_payment_queue (source_payment_id);
CREATE INDEX idx_spq_supplier_entity_id     ON public.supplier_payment_queue (supplier_entity_id);
CREATE INDEX idx_spq_supplier_id            ON public.supplier_payment_queue (supplier_id);
CREATE INDEX idx_spq_type                   ON public.supplier_payment_queue (type);
CREATE INDEX spbl_buyer_idx                 ON public.supplier_program_buyer_limit (buyer_entity_id);
CREATE INDEX spbl_supplier_idx              ON public.supplier_program_buyer_limit (supplier_entity_id);
CREATE INDEX spbo_supplier_idx              ON public.supplier_program_buyer_override (supplier_entity_id);
CREATE INDEX idx_suppliers_name             ON public.suppliers (name);
CREATE UNIQUE INDEX suppliers_registry_uq   ON public.suppliers (COALESCE(verification_source,'companies_house'), company_number) WHERE (company_number IS NOT NULL);
CREATE INDEX idx_user_profiles_role         ON public.user_profiles (role);
CREATE INDEX idx_user_profiles_supplier     ON public.user_profiles (supplier_id);


-- ===========================================================================
-- VIEWS  (all four have security_invoker = true)
-- ===========================================================================

CREATE VIEW public.buyer_invoices
  WITH (security_invoker = true) AS
 SELECT id, upload_id, buyer_id, supplier_identifier, supplier_name,
        buyer_doc_id     AS buyer_invoice_id,
        supplier_doc_id  AS supplier_invoice_id,
        partner_doc_id   AS partner_invoice_id,
        primary_id_field,
        doc_date         AS invoice_date,
        due_date, paid_date, amount, paid_amount, currency,
        invoice_status, status_change_date, cost_centre, po_number, gl_code,
        doc_subtype, raw_document_type, raw_amount, excluded
   FROM buyer_documents
  WHERE (doc_class = 'invoice'::text);

CREATE VIEW public.buyer_credit_notes
  WITH (security_invoker = true) AS
 SELECT id, upload_id, buyer_id, supplier_identifier, supplier_name,
        buyer_doc_id    AS buyer_cn_id,
        supplier_doc_id AS supplier_cn_id,
        partner_doc_id  AS partner_cn_id,
        primary_id_field,
        doc_date        AS cn_date,
        paid_date, amount, currency, doc_subtype,
        raw_document_type, raw_amount, excluded
   FROM buyer_documents
  WHERE (doc_class = 'credit_note'::text);

CREATE VIEW public.buyer_doctype_ledger
  WITH (security_invoker = true) AS
 SELECT buyer_id, upload_id,
        COALESCE(raw_document_type, ''::text) AS raw_document_type,
        sign_bucket, doc_class, doc_subtype,
        count(*) AS row_count,
        sum(amount) AS total_value,
        sum(CASE WHEN (amount = (0)::numeric) THEN 1 ELSE 0 END) AS zero_count
   FROM buyer_documents
  GROUP BY buyer_id, upload_id, COALESCE(raw_document_type, ''::text),
           sign_bucket, doc_class, doc_subtype;

-- factorflow_doctype_ledger unions invoices, credit_notes and
-- disregarded_documents. Reproduced from live introspection; it is long and
-- is the one object here most worth re-dumping rather than trusting a copy.
CREATE VIEW public.factorflow_doctype_ledger
  WITH (security_invoker = true) AS
 WITH rows_all AS (
   SELECT i.buyer_id,
          COALESCE(i.import_batch, '(unrecorded)'::text) AS import_batch,
          'invoice'::text AS doc_class,
          lower(btrim(COALESCE(i.raw_document_type, ''::text))) AS raw_value,
          i.raw_document_type AS raw_value_verbatim,
          i.sign_bucket,
          NULL::text AS doc_subtype,
          i.source_provider, i.amount, i.currency,
          i.invoice_date AS doc_date,
          ((i.funding_status = 'pending'::text) AND (i.funding_program IS NULL)
             AND (COALESCE(i.voided, false) = false)) AS freely_reclassifiable,
          (COALESCE(i.voided, false) AND (i.reclassified_to_id IS NOT NULL)) AS reclassified_out
     FROM invoices i
   UNION ALL
   SELECT c.buyer_id, COALESCE(c.import_batch, '(unrecorded)'::text), 'credit_note'::text,
          lower(btrim(COALESCE(c.raw_document_type, ''::text))), c.raw_document_type,
          c.sign_bucket, c.doc_subtype, c.source_provider, c.amount, c.currency, c.date,
          ((COALESCE(jsonb_array_length(c.allocations), 0) = 0) AND (COALESCE(c.voided, false) = false)),
          false
     FROM credit_notes c
   UNION ALL
   SELECT d.buyer_id, COALESCE(d.import_batch, '(unrecorded)'::text), 'disregard'::text,
          lower(btrim(COALESCE(d.raw_document_type, ''::text))), d.raw_document_type,
          d.sign_bucket, d.doc_subtype, d.source_provider, d.amount, d.currency, d.doc_date,
          true, false
     FROM disregarded_documents d
 )
 SELECT buyer_id, import_batch, raw_value,
        min(raw_value_verbatim) AS raw_value_sample,
        sign_bucket, doc_class, doc_subtype, currency,
        count(*) FILTER (WHERE (NOT reclassified_out)) AS row_count,
        sum(amount) FILTER (WHERE (NOT reclassified_out)) AS total_value,
        count(*) FILTER (WHERE reclassified_out) AS reclassified_out,
        min(doc_date) AS first_seen,
        max(doc_date) AS last_seen,
        count(*) FILTER (WHERE ((NOT freely_reclassifiable) AND (NOT reclassified_out))) AS locked_rows,
        ((sign_bucket = 'negative'::text) AND (doc_class = 'invoice'::text)) AS negative_as_invoice,
        (sign_bucket IS NULL) AS hand_created
   FROM rows_all
  GROUP BY buyer_id, import_batch, raw_value, sign_bucket, doc_class, doc_subtype, currency
 HAVING ((count(*) FILTER (WHERE (NOT reclassified_out)) > 0)
      OR (count(*) FILTER (WHERE reclassified_out) > 0));


-- ===========================================================================
-- NOT INCLUDED — obtain from a full dump
--   * 31 functions in public, including the four factorflow_* jobs
--   * 136 RLS policies
--   * 10 triggers
--   * sequence definitions
--   * grants and role definitions
-- ===========================================================================
