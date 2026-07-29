CREATE SEQUENCE public.audit_log_id_seq;

CREATE SEQUENCE public.daily_book_snapshots_id_seq;

CREATE SEQUENCE public.disregarded_documents_id_seq;

CREATE SEQUENCE public.entity_aliases_id_seq;

CREATE SEQUENCE public.holdback_payment_allocations_id_seq;

CREATE SEQUENCE public.payment_allocations_id_seq;

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
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  "timestamp" timestamp with time zone,
  display_time text
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
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.buyer_currency_paid_period (
  upload_id uuid NOT NULL,
  buyer_id text NOT NULL,
  ccy text NOT NULL,
  period_kind character(1) NOT NULL,
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
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  learned_under_provider text,
  last_seen_provider text,
  updated_at timestamp with time zone,
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
  sign_bucket text NOT NULL DEFAULT 
CASE
    WHEN (raw_amount < (0)::numeric) THEN 'negative'::text
    ELSE 'positive'::text
END,
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
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.buyer_status_aliases (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id text NOT NULL,
  raw_value text NOT NULL,
  canonical_value text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
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
  computed_at timestamp with time zone NOT NULL DEFAULT now(),
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
  created_at timestamp with time zone DEFAULT now(),
  created_by text,
  buyer_id text,
  snapshot_status text NOT NULL DEFAULT 'pending'::text,
  snapshot_error text,
  snapshot_started_at timestamp with time zone,
  snapshot_finished_at timestamp with time zone
);

CREATE TABLE public.buyers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text,
  street2 text,
  city text,
  state text,
  zip text,
  country text,
  company_number text,
  vat_number text,
  branches jsonb NOT NULL DEFAULT '[]'::jsonb,
  credit_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  single_invoice_limits jsonb NOT NULL DEFAULT '{}'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  onboarding_date date,
  paused boolean NOT NULL DEFAULT false,
  primary_contact text,
  primary_email text,
  primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text,
  secondary_email text,
  secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text,
  contact3_email text,
  contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text,
  contact4_email text,
  contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text,
  contact5_email text,
  contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamp with time zone,
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
  date date NOT NULL,
  reference text,
  supplier_id text NOT NULL,
  supplier_entity_id text,
  buyer_id text NOT NULL,
  buyer_entity_id text,
  allocations jsonb NOT NULL DEFAULT '[]'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  voided boolean NOT NULL DEFAULT false,
  voided_at timestamp with time zone,
  voided_by text,
  void_reason text,
  created_display text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  raw_document_type text,
  raw_amount numeric,
  doc_subtype text,
  source_provider text,
  sign_bucket text DEFAULT 
CASE
    WHEN (raw_amount IS NULL) THEN NULL::text
    WHEN (raw_amount < (0)::numeric) THEN 'negative'::text
    ELSE 'positive'::text
END,
  import_batch text,
  reclassified_from_type text,
  reclassified_from_id text,
  reclassified_at timestamp with time zone,
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
  superseded_at timestamp with time zone,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.csv_review_queue (
  id text NOT NULL DEFAULT (gen_random_uuid())::text,
  status text NOT NULL DEFAULT 'pending'::text,
  payload jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  invoice_id text,
  invoice_reference text,
  field_name text,
  field_label text,
  old_value text,
  new_value text,
  csv_row jsonb,
  resolved_at text
);

CREATE TABLE public.daily_book_snapshots (
  id bigint NOT NULL DEFAULT nextval('daily_book_snapshots_id_seq'::regclass),
  snapshot_date date NOT NULL,
  invoice_id text NOT NULL,
  capital_outstanding numeric,
  interest_outstanding numeric,
  penalty_outstanding numeric,
  holdback_outstanding numeric,
  penalty_accrued numeric,
  tranche_state jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  funding_program text,
  supplier_id text,
  supplier_entity_id text,
  buyer_id text,
  buyer_entity_id text,
  currency text,
  funding_status text,
  invoice_status text,
  current_invoice_status text,
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
  amount_post_dilutions numeric,
  holdback numeric,
  holdback_overdrawn numeric,
  debt_balance numeric,
  balance_owed numeric,
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
  voided_at timestamp with time zone,
  buyer_ref text,
  supplier_ref text,
  invoice_reference text,
  written_at timestamp with time zone,
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
  sign_bucket text DEFAULT 
CASE
    WHEN (raw_amount IS NULL) THEN NULL::text
    WHEN (raw_amount < (0)::numeric) THEN 'negative'::text
    ELSE 'positive'::text
END,
  doc_subtype text,
  source_provider text,
  import_batch text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  created_by uuid,
  reclassified_from_type text,
  reclassified_from_id text,
  reclassified_at timestamp with time zone,
  reclassified_by uuid
);

CREATE TABLE public.entity_aliases (
  id bigint NOT NULL DEFAULT nextval('entity_aliases_id_seq'::regclass),
  alias_name text NOT NULL,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  entity_name text
);

CREATE TABLE public.entity_notes (
  id text NOT NULL,
  entity_id text NOT NULL,
  entity_type text NOT NULL,
  text text NOT NULL,
  author text,
  created_at timestamp with time zone NOT NULL DEFAULT now()
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
  max_sup_dil_live numeric NOT NULL DEFAULT 0,
  max_sup_dil_30 numeric NOT NULL DEFAULT 0,
  max_sup_dil_90 numeric NOT NULL DEFAULT 0,
  max_fund_dil_live numeric NOT NULL DEFAULT 0,
  max_fund_dil_30 numeric NOT NULL DEFAULT 0,
  max_fund_dil_90 numeric NOT NULL DEFAULT 0,
  eligible_suppliers jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_buyers jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_buyer_jurisdictions jsonb NOT NULL DEFAULT '[]'::jsonb,
  eligible_supplier_jurisdictions jsonb NOT NULL DEFAULT '[]'::jsonb,
  fund_flows jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_date date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
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
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.holdback_payments (
  hb_payment_id text NOT NULL,
  source_invoice_id text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date NOT NULL,
  supplier_id text,
  supplier_entity_id text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.invoices (
  id text NOT NULL,
  supplier_id text NOT NULL,
  supplier_entity_id text,
  buyer_id text NOT NULL,
  buyer_entity_id text,
  amount numeric NOT NULL,
  currency text NOT NULL,
  invoice_date date NOT NULL,
  due_date date NOT NULL,
  buyer_ref text,
  supplier_ref text,
  purchase_order text,
  invoice_reference text,
  buyer_received_date date,
  invoice_status text NOT NULL DEFAULT 'Received'::text,
  funding_status text NOT NULL DEFAULT 'pending'::text,
  invoice_status_history jsonb NOT NULL DEFAULT '[]'::jsonb,
  current_invoice_status text,
  disputed_date date,
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
  voided_at timestamp with time zone,
  voided_by text,
  void_reason text,
  adjustments jsonb NOT NULL DEFAULT '[]'::jsonb,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  capital_outstanding numeric,
  interest_outstanding numeric,
  penalty_outstanding numeric,
  holdback_outstanding numeric,
  holdback_overdrawn numeric,
  debt_balance numeric,
  balance_owed numeric,
  amount_post_dilutions numeric,
  created_date date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  written_down_short boolean DEFAULT false,
  write_down_date date,
  pending_doctype_confirmation boolean NOT NULL DEFAULT false,
  raw_document_type text,
  raw_amount numeric,
  source_provider text,
  sign_bucket text DEFAULT 
CASE
    WHEN (raw_amount IS NULL) THEN NULL::text
    WHEN (raw_amount < (0)::numeric) THEN 'negative'::text
    ELSE 'positive'::text
END,
  import_batch text,
  reclassified_to_type text,
  reclassified_to_id text,
  reclassified_at timestamp with time zone,
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
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  kind text NOT NULL DEFAULT 'funded_recovery'::text
);

CREATE TABLE public.payments (
  payment_id text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date NOT NULL,
  reference text,
  direction text NOT NULL DEFAULT 'inbound'::text,
  buyer_id text,
  buyer_entity_id text,
  supplier_id text,
  supplier_entity_id text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
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
  converted_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  created_by uuid,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.prospect_notes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  prospect_supplier_id uuid NOT NULL,
  content text NOT NULL,
  note_type text NOT NULL DEFAULT 'user'::text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.prospect_suppliers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  buyer_id text NOT NULL,
  supplier_identifier text NOT NULL,
  currency text NOT NULL,
  status text NOT NULL DEFAULT 'lead'::text,
  first_seen_at timestamp with time zone NOT NULL DEFAULT now(),
  last_seen_at timestamp with time zone NOT NULL DEFAULT now(),
  registry_id text,
  legal_name text,
  verified_at timestamp with time zone,
  contact_name text,
  contact_email text,
  contact_phone text,
  converted_supplier_id text,
  converted_at timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  supplier_name text,
  next_action_at timestamp with time zone,
  next_action_note text,
  verification_source text,
  verification_jurisdiction text,
  verified_by uuid,
  verification_notes text,
  verification_raw jsonb,
  group_id uuid,
  branch_decision text DEFAULT 'unassigned'::text,
  converted_branch_id text,
  branch_decision_at timestamp with time zone,
  branch_decision_by uuid
);

CREATE TABLE public.provider_entity_aliases (
  provider_id text,
  entity_type text NOT NULL,
  external_string text NOT NULL,
  pelagic_entity_id text NOT NULL,
  first_seen_at timestamp with time zone NOT NULL DEFAULT now(),
  first_seen_in_upload_id text,
  verified_by text,
  verified_at timestamp with time zone,
  notes text,
  buyer_entity_id text,
  id uuid NOT NULL DEFAULT gen_random_uuid()
);

CREATE TABLE public.rate_recompute_queue (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  triggered_by text NOT NULL,
  benchmark_id text,
  trigger_entity_id text,
  trigger_program_id text,
  triggered_at timestamp with time zone NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'pending'::text,
  affected_count integer,
  completed_at timestamp with time zone,
  error text
);

CREATE TABLE public.service_providers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text,
  street2 text,
  city text,
  state text,
  zip text,
  country text,
  company_number text,
  vat_number text,
  bank_name text,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  role text,
  onboarding_date date,
  account_name text,
  sort_code text,
  account_number text,
  iban text,
  bic text,
  primary_contact text,
  primary_email text,
  primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text,
  secondary_email text,
  secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text,
  contact3_email text,
  contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text,
  contact4_email text,
  contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text,
  contact5_email text,
  contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  paused boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamp with time zone,
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
  ready_at timestamp with time zone,
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE TABLE public.supplier_payment_queue (
  id text NOT NULL,
  type text NOT NULL,
  status text NOT NULL,
  amount numeric NOT NULL,
  currency text NOT NULL,
  date date,
  supplier_id text NOT NULL,
  supplier_entity_id text,
  invoice_id text,
  invoice_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  source_invoice_id text,
  source_payment_id text,
  funding_program text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  supplier_name text,
  bank_name text,
  bank_details text,
  program_id text,
  program_name text,
  created_display text,
  executed_at text,
  executed_display text,
  hb_payment_id text,
  is_bundle boolean NOT NULL DEFAULT false,
  holdback_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  gross_amount numeric,
  deductions jsonb NOT NULL DEFAULT '[]'::jsonb,
  deduction_total numeric NOT NULL DEFAULT 0,
  notes jsonb NOT NULL DEFAULT '[]'::jsonb,
  cancelled_at text,
  cancelled_display text,
  failed_at text,
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
  computed_at timestamp with time zone NOT NULL DEFAULT now(),
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
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  invoice_override_value numeric
);

CREATE TABLE public.suppliers (
  id text NOT NULL,
  name text NOT NULL,
  street1 text,
  street2 text,
  city text,
  state text,
  zip text,
  country text,
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
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  jurisdiction text DEFAULT 'United Kingdom'::text,
  status text DEFAULT 'Active'::text,
  onboarding_date date,
  paused boolean NOT NULL DEFAULT false,
  rates jsonb NOT NULL DEFAULT '[]'::jsonb,
  account_name text,
  sort_code text,
  account_number text,
  iban text,
  bic text,
  primary_contact text,
  primary_email text,
  primary_phone text,
  primary_signatory boolean NOT NULL DEFAULT false,
  secondary_contact text,
  secondary_email text,
  secondary_phone text,
  secondary_signatory boolean NOT NULL DEFAULT false,
  contact3_name text,
  contact3_email text,
  contact3_phone text,
  contact3_signatory boolean NOT NULL DEFAULT false,
  contact4_name text,
  contact4_email text,
  contact4_phone text,
  contact4_signatory boolean NOT NULL DEFAULT false,
  contact5_name text,
  contact5_email text,
  contact5_phone text,
  contact5_signatory boolean NOT NULL DEFAULT false,
  entity_source text DEFAULT 'manual'::text,
  directors jsonb NOT NULL DEFAULT '[]'::jsonb,
  company_status text,
  incorporation_date date,
  sic_codes jsonb NOT NULL DEFAULT '[]'::jsonb,
  ch_last_updated timestamp with time zone,
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
  role text NOT NULL,
  supplier_id text,
  is_active boolean DEFAULT true,
  last_login_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  status text DEFAULT 'active'::text,
  buyer_id text,
  branch_id text
);

ALTER TABLE public.audit_log ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);

ALTER TABLE public.benchmarks ADD CONSTRAINT benchmarks_pkey PRIMARY KEY (id);

ALTER TABLE public.buyer_currency_paid_period ADD CONSTRAINT buyer_currency_paid_period_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.buyer_currency_paid_period ADD CONSTRAINT buyer_currency_paid_period_pkey PRIMARY KEY (upload_id, ccy, period_kind, period_key);

ALTER TABLE public.buyer_currency_paid_period ADD CONSTRAINT buyer_currency_paid_period_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_currency_weekly ADD CONSTRAINT buyer_currency_weekly_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.buyer_currency_weekly ADD CONSTRAINT buyer_currency_weekly_pkey PRIMARY KEY (upload_id, ccy, yw);

ALTER TABLE public.buyer_currency_weekly ADD CONSTRAINT buyer_currency_weekly_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_doctype_aliases ADD CONSTRAINT buyer_doctype_aliases_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_doctype_aliases ADD CONSTRAINT buyer_doctype_aliases_canonical_value_check CHECK ((canonical_value = ANY (ARRAY['invoice'::text, 'credit_note'::text, 'disregard'::text])));

ALTER TABLE public.buyer_doctype_aliases ADD CONSTRAINT buyer_doctype_aliases_pkey PRIMARY KEY (buyer_id, raw_value, sign_bucket);

ALTER TABLE public.buyer_doctype_aliases ADD CONSTRAINT buyer_doctype_aliases_raw_value_normalised CHECK ((raw_value = lower(btrim(raw_value))));

ALTER TABLE public.buyer_doctype_aliases ADD CONSTRAINT buyer_doctype_aliases_sign_bucket_check CHECK ((sign_bucket = ANY (ARRAY['positive'::text, 'negative'::text])));

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_amount_check CHECK ((amount >= (0)::numeric));

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id);

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_doc_class_check CHECK ((doc_class = ANY (ARRAY['invoice'::text, 'credit_note'::text, 'disregard'::text])));

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_invoice_status_check CHECK ((invoice_status = ANY (ARRAY['paid'::text, 'cancelled'::text, 'rejected'::text, 'approved'::text, 'processing'::text])));

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_pkey PRIMARY KEY (id);

ALTER TABLE public.buyer_documents ADD CONSTRAINT buyer_documents_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_documents ADD CONSTRAINT cn_has_no_due_date CHECK (((doc_class <> 'credit_note'::text) OR (due_date IS NULL)));

ALTER TABLE public.buyer_documents ADD CONSTRAINT cn_has_no_status CHECK (((doc_class <> 'credit_note'::text) OR (invoice_status IS NULL)));

ALTER TABLE public.buyer_status_aliases ADD CONSTRAINT buyer_status_aliases_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_status_aliases ADD CONSTRAINT buyer_status_aliases_buyer_id_raw_value_key UNIQUE (buyer_id, raw_value);

ALTER TABLE public.buyer_status_aliases ADD CONSTRAINT buyer_status_aliases_canonical_value_check CHECK ((canonical_value = ANY (ARRAY['paid'::text, 'cancelled'::text, 'rejected'::text, 'approved'::text, 'processing'::text])));

ALTER TABLE public.buyer_status_aliases ADD CONSTRAINT buyer_status_aliases_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

ALTER TABLE public.buyer_status_aliases ADD CONSTRAINT buyer_status_aliases_pkey PRIMARY KEY (id);

ALTER TABLE public.buyer_supplier_monthly ADD CONSTRAINT buyer_supplier_monthly_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.buyer_supplier_monthly ADD CONSTRAINT buyer_supplier_monthly_pkey PRIMARY KEY (upload_id, ccy, supplier_identifier, ym);

ALTER TABLE public.buyer_supplier_monthly ADD CONSTRAINT buyer_supplier_monthly_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_upload_snapshots ADD CONSTRAINT buyer_upload_snapshots_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.buyer_upload_snapshots ADD CONSTRAINT buyer_upload_snapshots_pkey PRIMARY KEY (upload_id);

ALTER TABLE public.buyer_upload_snapshots ADD CONSTRAINT buyer_upload_snapshots_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_upload_supplier_counts ADD CONSTRAINT buyer_upload_supplier_counts_pkey PRIMARY KEY (buyer_id, upload_id, supplier_identifier);

ALTER TABLE public.buyer_upload_supplier_counts ADD CONSTRAINT buyer_upload_supplier_counts_upload_fk FOREIGN KEY (upload_id) REFERENCES buyer_uploads(id) ON DELETE CASCADE;

ALTER TABLE public.buyer_uploads ADD CONSTRAINT buyer_uploads_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.buyer_uploads ADD CONSTRAINT buyer_uploads_pkey PRIMARY KEY (id);

ALTER TABLE public.buyers ADD CONSTRAINT buyers_company_number_unique UNIQUE (company_number);

ALTER TABLE public.buyers ADD CONSTRAINT buyers_pkey PRIMARY KEY (id);

ALTER TABLE public.credit_notes ADD CONSTRAINT credit_notes_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id);

ALTER TABLE public.credit_notes ADD CONSTRAINT credit_notes_pkey PRIMARY KEY (credit_note_id);

ALTER TABLE public.credit_notes ADD CONSTRAINT credit_notes_reclassified_from_type_check CHECK (((reclassified_from_type IS NULL) OR (reclassified_from_type = ANY (ARRAY['invoice'::text, 'disregard'::text]))));

ALTER TABLE public.credit_notes ADD CONSTRAINT credit_notes_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_associated_buyer_id_fkey FOREIGN KEY (associated_buyer_id) REFERENCES buyers(id);

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_associated_supplier_id_fkey FOREIGN KEY (associated_supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_kind_check CHECK ((provider_kind = ANY (ARRAY['platform'::text, 'buyer_direct'::text, 'supplier_direct'::text, 'other'::text])));

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_pkey PRIMARY KEY (provider_id);

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_provenance_check CHECK ((((provider_kind = 'buyer_direct'::text) AND (associated_buyer_id IS NOT NULL) AND (associated_supplier_id IS NULL)) OR ((provider_kind = 'supplier_direct'::text) AND (associated_supplier_id IS NOT NULL) AND (associated_buyer_id IS NULL)) OR ((provider_kind = 'platform'::text) AND (associated_buyer_id IS NULL) AND (associated_supplier_id IS NULL)) OR (provider_kind = 'other'::text)));

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_status_check CHECK ((status = ANY (ARRAY['active'::text, 'superseded'::text])));

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_superseded_by_provider_id_fkey FOREIGN KEY (superseded_by_provider_id) REFERENCES csv_providers(provider_id);

ALTER TABLE public.csv_providers ADD CONSTRAINT csv_providers_supersession_check CHECK ((((status = 'active'::text) AND (superseded_by_provider_id IS NULL) AND (superseded_at IS NULL)) OR ((status = 'superseded'::text) AND (superseded_by_provider_id IS NOT NULL) AND (superseded_at IS NOT NULL))));

ALTER TABLE public.csv_review_queue ADD CONSTRAINT csv_review_queue_pkey PRIMARY KEY (id);

ALTER TABLE public.daily_book_snapshots ADD CONSTRAINT daily_book_snapshots_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

ALTER TABLE public.daily_book_snapshots ADD CONSTRAINT daily_book_snapshots_pkey PRIMARY KEY (id);

ALTER TABLE public.daily_book_snapshots ADD CONSTRAINT daily_book_snapshots_snapshot_date_invoice_id_key UNIQUE (snapshot_date, invoice_id);

ALTER TABLE public.disregarded_documents ADD CONSTRAINT disregarded_documents_amount_check CHECK ((amount >= (0)::numeric));

ALTER TABLE public.disregarded_documents ADD CONSTRAINT disregarded_documents_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE CASCADE;

ALTER TABLE public.disregarded_documents ADD CONSTRAINT disregarded_documents_pkey PRIMARY KEY (id);

ALTER TABLE public.disregarded_documents ADD CONSTRAINT disregarded_documents_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;

ALTER TABLE public.entity_aliases ADD CONSTRAINT entity_aliases_pkey PRIMARY KEY (id);

ALTER TABLE public.entity_notes ADD CONSTRAINT entity_notes_pkey PRIMARY KEY (id);

ALTER TABLE public.funding_programs ADD CONSTRAINT funding_programs_pkey PRIMARY KEY (id);

ALTER TABLE public.holdback_payment_allocations ADD CONSTRAINT holdback_payment_allocations_hb_payment_id_fkey FOREIGN KEY (hb_payment_id) REFERENCES holdback_payments(hb_payment_id) ON DELETE CASCADE;

ALTER TABLE public.holdback_payment_allocations ADD CONSTRAINT holdback_payment_allocations_pkey PRIMARY KEY (id);

ALTER TABLE public.holdback_payment_allocations ADD CONSTRAINT holdback_payment_allocations_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.holdback_payments ADD CONSTRAINT holdback_payments_pkey PRIMARY KEY (hb_payment_id);

ALTER TABLE public.holdback_payments ADD CONSTRAINT holdback_payments_source_invoice_id_fkey FOREIGN KEY (source_invoice_id) REFERENCES invoices(id);

ALTER TABLE public.holdback_payments ADD CONSTRAINT holdback_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.invoices ADD CONSTRAINT invoices_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id);

ALTER TABLE public.invoices ADD CONSTRAINT invoices_funding_program_fkey FOREIGN KEY (funding_program) REFERENCES funding_programs(id);

ALTER TABLE public.invoices ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);

ALTER TABLE public.invoices ADD CONSTRAINT invoices_reclassified_to_type_check CHECK (((reclassified_to_type IS NULL) OR (reclassified_to_type = ANY (ARRAY['credit_note'::text, 'disregard'::text]))));

ALTER TABLE public.invoices ADD CONSTRAINT invoices_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id);

ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_kind_check CHECK ((kind = ANY (ARRAY['funded_recovery'::text, 'pass_through'::text])));

ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(payment_id) ON DELETE CASCADE;

ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_pkey PRIMARY KEY (id);

ALTER TABLE public.payment_allocations ADD CONSTRAINT payment_allocations_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.payments ADD CONSTRAINT payments_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id);

ALTER TABLE public.payments ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);

ALTER TABLE public.payments ADD CONSTRAINT payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.prospect_groups ADD CONSTRAINT prospect_groups_pkey PRIMARY KEY (id);

ALTER TABLE public.prospect_groups ADD CONSTRAINT prospect_groups_registry_id_unique UNIQUE (registry_id);

ALTER TABLE public.prospect_notes ADD CONSTRAINT prospect_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

ALTER TABLE public.prospect_notes ADD CONSTRAINT prospect_notes_note_type_check CHECK ((note_type = ANY (ARRAY['user'::text, 'system'::text])));

ALTER TABLE public.prospect_notes ADD CONSTRAINT prospect_notes_pkey PRIMARY KEY (id);

ALTER TABLE public.prospect_notes ADD CONSTRAINT prospect_notes_prospect_supplier_id_fkey FOREIGN KEY (prospect_supplier_id) REFERENCES prospect_suppliers(id) ON DELETE CASCADE;

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_branch_decision_chk CHECK ((branch_decision = ANY (ARRAY['unassigned'::text, 'parent_main'::text, 'branch'::text, 'skip'::text])));

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_buyer_id_supplier_identifier_currency_key UNIQUE (buyer_id, supplier_identifier, currency);

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_group_id_fkey FOREIGN KEY (group_id) REFERENCES prospect_groups(id) ON DELETE SET NULL;

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_pkey PRIMARY KEY (id);

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_status_check CHECK ((status = ANY (ARRAY['lead'::text, 'contacted'::text, 'interested'::text, 'negotiating'::text, 'onboarding'::text, 'converted'::text, 'declined'::text])));

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_verification_source_check CHECK (((verification_source IS NULL) OR (verification_source = ANY (ARRAY['companies_house'::text, 'manual'::text, 'other'::text]))));

ALTER TABLE public.prospect_suppliers ADD CONSTRAINT prospect_suppliers_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id);

ALTER TABLE public.provider_entity_aliases ADD CONSTRAINT pea_buyer_provider_required CHECK (((entity_type <> 'buyer'::text) OR (provider_id IS NOT NULL)));

ALTER TABLE public.provider_entity_aliases ADD CONSTRAINT provider_entity_aliases_pkey PRIMARY KEY (id);

ALTER TABLE public.provider_entity_aliases ADD CONSTRAINT provider_entity_aliases_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES csv_providers(provider_id);

ALTER TABLE public.provider_entity_aliases ADD CONSTRAINT provider_entity_aliases_type_check CHECK ((entity_type = ANY (ARRAY['supplier'::text, 'buyer'::text])));

ALTER TABLE public.rate_recompute_queue ADD CONSTRAINT rate_recompute_queue_pkey PRIMARY KEY (id);

ALTER TABLE public.service_providers ADD CONSTRAINT service_providers_pkey PRIMARY KEY (id);

ALTER TABLE public.supplier_backfill ADD CONSTRAINT supplier_backfill_pkey PRIMARY KEY (supplier_entity_id);

ALTER TABLE public.supplier_payment_queue ADD CONSTRAINT supplier_payment_queue_funding_program_fkey FOREIGN KEY (funding_program) REFERENCES funding_programs(id);

ALTER TABLE public.supplier_payment_queue ADD CONSTRAINT supplier_payment_queue_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id);

ALTER TABLE public.supplier_payment_queue ADD CONSTRAINT supplier_payment_queue_pkey PRIMARY KEY (id);

ALTER TABLE public.supplier_payment_queue ADD CONSTRAINT supplier_payment_queue_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id);

ALTER TABLE public.supplier_program_buyer_limit ADD CONSTRAINT supplier_program_buyer_limit_pkey PRIMARY KEY (funding_program, supplier_entity_id, buyer_entity_id);

ALTER TABLE public.supplier_program_buyer_override ADD CONSTRAINT supplier_program_buyer_override_pkey PRIMARY KEY (funding_program, supplier_entity_id, buyer_entity_id);

ALTER TABLE public.suppliers ADD CONSTRAINT suppliers_company_number_unique UNIQUE (company_number);

ALTER TABLE public.suppliers ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);

ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_buyer_id_fkey FOREIGN KEY (buyer_id) REFERENCES buyers(id) ON DELETE RESTRICT;

ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (id);

CREATE INDEX bcw_upload_ccy_idx ON public.buyer_currency_weekly USING btree (upload_id, ccy);

CREATE INDEX bcw_upload_idx ON public.buyer_currency_weekly USING btree (upload_id);

CREATE INDEX bcw_upload_yr_idx ON public.buyer_currency_weekly USING btree (upload_id, yr);

CREATE INDEX bi_snapshots_buyer_idx ON public.buyer_upload_snapshots USING btree (buyer_id);

CREATE INDEX bsm_upload_ccy_idx ON public.buyer_supplier_monthly USING btree (upload_id, ccy);

CREATE INDEX bsm_upload_idx ON public.buyer_supplier_monthly USING btree (upload_id);

CREATE INDEX bsm_upload_yr_idx ON public.buyer_supplier_monthly USING btree (upload_id, yr);

CREATE INDEX buyer_currency_paid_period_ccy_period_idx ON public.buyer_currency_paid_period USING btree (upload_id, ccy, period_kind);

CREATE UNIQUE INDEX buyers_registry_uq ON public.buyers USING btree (COALESCE(verification_source, 'companies_house'::text), company_number) WHERE (company_number IS NOT NULL);

CREATE INDEX credit_notes_import_batch_idx ON public.credit_notes USING btree (import_batch) WHERE (import_batch IS NOT NULL);

CREATE INDEX csv_providers_status_idx ON public.csv_providers USING btree (status) WHERE (status = 'active'::text);

CREATE INDEX daily_book_snapshots_backfilled_idx ON public.daily_book_snapshots USING btree (is_backfilled);

CREATE INDEX daily_book_snapshots_date_idx ON public.daily_book_snapshots USING btree (snapshot_date);

CREATE UNIQUE INDEX daily_book_snapshots_invoice_date_uniq ON public.daily_book_snapshots USING btree (invoice_id, snapshot_date);

CREATE INDEX daily_book_snapshots_sup_prog_date_idx ON public.daily_book_snapshots USING btree (supplier_id, funding_program, snapshot_date);

CREATE INDEX daily_book_snapshots_supent_prog_date_idx ON public.daily_book_snapshots USING btree (supplier_entity_id, funding_program, snapshot_date);

CREATE INDEX disregarded_documents_batch_idx ON public.disregarded_documents USING btree (import_batch);

CREATE INDEX disregarded_documents_buyer_idx ON public.disregarded_documents USING btree (buyer_id);

CREATE INDEX idx_aliases_lookup ON public.entity_aliases USING btree (entity_type, alias_name);

CREATE INDEX idx_audit_buyer_id ON public.audit_log USING btree (buyer_id);

CREATE INDEX idx_audit_created_at ON public.audit_log USING btree (created_at);

CREATE INDEX idx_audit_invoice_id ON public.audit_log USING btree (invoice_id);

CREATE INDEX idx_audit_supplier_entity_id ON public.audit_log USING btree (supplier_entity_id);

CREATE INDEX idx_audit_supplier_id ON public.audit_log USING btree (supplier_id);

CREATE INDEX idx_bd_buyer_ccy ON public.buyer_documents USING btree (buyer_id, currency, doc_class);

CREATE INDEX idx_bd_buyer_sup ON public.buyer_documents USING btree (buyer_id, supplier_identifier);

CREATE INDEX idx_bd_reclass ON public.buyer_documents USING btree (buyer_id, raw_document_type, sign_bucket);

CREATE INDEX idx_bd_upload_class ON public.buyer_documents USING btree (upload_id, doc_class) WHERE (NOT excluded);

CREATE INDEX idx_buyer_uploads_created_at ON public.buyer_uploads USING btree (created_at DESC);

CREATE INDEX idx_buyers_name ON public.buyers USING btree (name);

CREATE INDEX idx_cn_buyer_id ON public.credit_notes USING btree (buyer_id);

CREATE INDEX idx_cn_supplier_entity_id ON public.credit_notes USING btree (supplier_entity_id);

CREATE INDEX idx_cn_supplier_id ON public.credit_notes USING btree (supplier_id);

CREATE INDEX idx_csv_status ON public.csv_review_queue USING btree (status);

CREATE INDEX idx_entity_notes_entity ON public.entity_notes USING btree (entity_type, entity_id);

CREATE INDEX idx_hba_hb_payment_id ON public.holdback_payment_allocations USING btree (hb_payment_id);

CREATE INDEX idx_hba_supplier_id ON public.holdback_payment_allocations USING btree (supplier_id);

CREATE INDEX idx_hbp_source_invoice ON public.holdback_payments USING btree (source_invoice_id);

CREATE INDEX idx_hbp_supplier_id ON public.holdback_payments USING btree (supplier_id);

CREATE INDEX idx_invoices_buyer_entity_id ON public.invoices USING btree (buyer_entity_id);

CREATE INDEX idx_invoices_buyer_id ON public.invoices USING btree (buyer_id);

CREATE INDEX idx_invoices_funding_program ON public.invoices USING btree (funding_program);

CREATE INDEX idx_invoices_funding_status ON public.invoices USING btree (funding_status);

CREATE INDEX idx_invoices_supplier_entity_id ON public.invoices USING btree (supplier_entity_id);

CREATE INDEX idx_invoices_supplier_id ON public.invoices USING btree (supplier_id);

CREATE INDEX idx_pa_invoice_id ON public.payment_allocations USING btree (invoice_id);

CREATE INDEX idx_pa_payment_id ON public.payment_allocations USING btree (payment_id);

CREATE INDEX idx_pa_supplier_entity_id ON public.payment_allocations USING btree (supplier_entity_id);

CREATE INDEX idx_pa_supplier_id ON public.payment_allocations USING btree (supplier_id);

CREATE INDEX idx_payments_buyer_id ON public.payments USING btree (buyer_id);

CREATE INDEX idx_payments_date ON public.payments USING btree (date);

CREATE INDEX idx_payments_supplier_id ON public.payments USING btree (supplier_id);

CREATE INDEX idx_prospect_groups_converted_supplier_id ON public.prospect_groups USING btree (converted_supplier_id) WHERE (converted_supplier_id IS NOT NULL);

CREATE INDEX idx_prospect_groups_registry_id ON public.prospect_groups USING btree (registry_id);

CREATE INDEX idx_prospect_suppliers_group_id ON public.prospect_suppliers USING btree (group_id) WHERE (group_id IS NOT NULL);

CREATE INDEX idx_snapshots_date ON public.daily_book_snapshots USING btree (snapshot_date);

CREATE INDEX idx_spq_source_payment_id ON public.supplier_payment_queue USING btree (source_payment_id);

CREATE INDEX idx_spq_supplier_entity_id ON public.supplier_payment_queue USING btree (supplier_entity_id);

CREATE INDEX idx_spq_supplier_id ON public.supplier_payment_queue USING btree (supplier_id);

CREATE INDEX idx_spq_type ON public.supplier_payment_queue USING btree (type);

CREATE INDEX idx_suppliers_name ON public.suppliers USING btree (name);

CREATE INDEX idx_user_profiles_role ON public.user_profiles USING btree (role);

CREATE INDEX idx_user_profiles_supplier ON public.user_profiles USING btree (supplier_id);

CREATE INDEX invoices_import_batch_idx ON public.invoices USING btree (import_batch) WHERE (import_batch IS NOT NULL);

CREATE INDEX invoices_pending_doctype_idx ON public.invoices USING btree (buyer_id) WHERE pending_doctype_confirmation;

CREATE INDEX payment_allocations_kind_idx ON public.payment_allocations USING btree (kind);

CREATE UNIQUE INDEX pea_buyer_uq ON public.provider_entity_aliases USING btree (provider_id, external_string) WHERE (entity_type = 'buyer'::text);

CREATE UNIQUE INDEX pea_supplier_uq ON public.provider_entity_aliases USING btree (buyer_entity_id, external_string) WHERE ((entity_type = 'supplier'::text) AND (buyer_entity_id IS NOT NULL));

CREATE INDEX prospect_notes_supplier_idx ON public.prospect_notes USING btree (prospect_supplier_id, created_at DESC);

CREATE INDEX prospect_suppliers_buyer_idx ON public.prospect_suppliers USING btree (buyer_id);

CREATE INDEX prospect_suppliers_cross_buyer_idx ON public.prospect_suppliers USING btree (verification_jurisdiction, registry_id) WHERE ((registry_id IS NOT NULL) AND (verified_at IS NOT NULL));

CREATE INDEX prospect_suppliers_last_seen_idx ON public.prospect_suppliers USING btree (last_seen_at DESC);

CREATE INDEX prospect_suppliers_next_action_idx ON public.prospect_suppliers USING btree (next_action_at) WHERE ((next_action_at IS NOT NULL) AND (status <> ALL (ARRAY['converted'::text, 'declined'::text])));

CREATE INDEX prospect_suppliers_registry_idx ON public.prospect_suppliers USING btree (registry_id) WHERE (registry_id IS NOT NULL);

CREATE INDEX prospect_suppliers_status_idx ON public.prospect_suppliers USING btree (status) WHERE (status <> ALL (ARRAY['converted'::text, 'declined'::text]));

CREATE INDEX provider_entity_aliases_pelagic_idx ON public.provider_entity_aliases USING btree (pelagic_entity_id, entity_type);

CREATE INDEX rate_recompute_queue_status_triggered_at_idx ON public.rate_recompute_queue USING btree (status, triggered_at) WHERE (status = ANY (ARRAY['pending'::text, 'running'::text]));

CREATE INDEX spbl_buyer_idx ON public.supplier_program_buyer_limit USING btree (buyer_entity_id);

CREATE INDEX spbl_supplier_idx ON public.supplier_program_buyer_limit USING btree (supplier_entity_id);

CREATE INDEX spbo_supplier_idx ON public.supplier_program_buyer_override USING btree (supplier_entity_id);

CREATE UNIQUE INDEX suppliers_registry_uq ON public.suppliers USING btree (COALESCE(verification_source, 'companies_house'::text), company_number) WHERE (company_number IS NOT NULL);

CREATE OR REPLACE FUNCTION public.broadcast_invoice_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  rec   record;
  body  jsonb;
begin
  rec := coalesce(new, old);

  body := jsonb_build_object(
    'operation',  lower(tg_op),
    'record',     to_jsonb(coalesce(new, old)),
    'old_record', case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end
  );

  -- realtime.send(payload jsonb, event text, topic text, private boolean)
  if rec.supplier_id is not null then
    perform realtime.send(body, 'invoice_change', 'supplier:' || rec.supplier_id, true);
  end if;

  if rec.supplier_entity_id is not null
     and rec.supplier_entity_id is distinct from rec.supplier_id then
    perform realtime.send(body, 'invoice_change', 'supplier_entity:' || rec.supplier_entity_id, true);
  end if;

  if rec.buyer_id is not null then
    perform realtime.send(body, 'invoice_change', 'buyer:' || rec.buyer_id, true);
  end if;

  if rec.buyer_entity_id is not null
     and rec.buyer_entity_id is distinct from rec.buyer_id then
    perform realtime.send(body, 'invoice_change', 'buyer_entity:' || rec.buyer_entity_id, true);
  end if;

  return null;  -- AFTER trigger
end;
$function$
;

CREATE OR REPLACE FUNCTION public.compute_buyer_snapshot(p_upload_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public'
 SET statement_timeout TO '300s'
AS $function$
DECLARE
  v_buyer_id           text;
  v_started_at         timestamptz := clock_timestamp();
  v_invoice_count      integer;
  v_cn_count           integer;
  v_stats              jsonb;
  v_overall            jsonb;
  v_per_period         jsonb;
  v_warnings           jsonb := '[]'::jsonb;
  v_upload_meta        jsonb;
  v_min_date           date;
  v_max_date           date;
  v_years              int[];
  v_first_full_month   text;
  v_last_full_month    text;
  v_first_full_week    text;
  v_last_full_week     text;
  v_first_full_quarter text;
  v_last_full_quarter  text;
  v_top_n              int := 5;
  v_min_paid_sample    int := 20;
  v_fair               jsonb;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_internal_user() THEN
    RAISE EXCEPTION 'Only internal users can compute snapshots';
  END IF;

  SELECT
    buyer_id,
    jsonb_build_object(
      'id', id, 'buyer_label', buyer_label, 'notes', notes,
      'invoice_file_name', invoice_file_name, 'cn_file_name', cn_file_name,
      'currencies_seen', currencies_seen, 'invoice_count', invoice_count,
      'cn_count', cn_count, 'supplier_count', supplier_count,
      'date_range_min', date_range_min, 'date_range_max', date_range_max,
      'created_at', created_at, 'created_by', created_by, 'buyer_id', buyer_id
    )
  INTO v_buyer_id, v_upload_meta
  FROM buyer_uploads
  WHERE id = p_upload_id;

  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Upload % has null buyer_id or does not exist', p_upload_id;
  END IF;

  DROP TABLE IF EXISTS _bsm;
  CREATE TEMP TABLE _bsm ON COMMIT DROP AS
  SELECT * FROM buyer_supplier_monthly WHERE upload_id = p_upload_id;
  CREATE INDEX _bsm_ccy_sid ON _bsm(ccy, supplier_identifier);
  CREATE INDEX _bsm_yr      ON _bsm(yr);
  CREATE INDEX _bsm_ym      ON _bsm(ym);

  v_invoice_count := COALESCE((SELECT sum(invoice_count) FROM _bsm), 0)::integer;
  v_cn_count := COALESCE((SELECT sum(cn_count) FROM _bsm), 0)::integer;

  IF v_invoice_count = 0 THEN
    v_warnings := v_warnings || to_jsonb('No non-excluded invoice rows; analysis will be empty.'::text);
  END IF;

  SELECT min(first_invoice_in_month) INTO v_min_date FROM _bsm WHERE invoice_count > 0;
  SELECT max(last_invoice_in_month)  INTO v_max_date FROM _bsm WHERE invoice_count > 0;
  SELECT array_agg(DISTINCT yr ORDER BY yr DESC) INTO v_years FROM _bsm;

  v_first_full_month := CASE
    WHEN v_min_date IS NULL THEN NULL
    WHEN extract(day FROM v_min_date) = 1 THEN to_char(v_min_date, 'YYYY-MM')
    ELSE to_char(date_trunc('month', v_min_date) + interval '1 month', 'YYYY-MM')
  END;
  v_last_full_month := CASE
    WHEN v_max_date IS NULL THEN NULL
    WHEN v_max_date = (date_trunc('month', v_max_date) + interval '1 month - 1 day')::date
         THEN to_char(v_max_date, 'YYYY-MM')
    ELSE to_char(date_trunc('month', v_max_date) - interval '1 day', 'YYYY-MM')
  END;
  v_first_full_week := CASE
    WHEN v_min_date IS NULL THEN NULL
    WHEN extract(isodow FROM v_min_date) = 1 THEN to_char(v_min_date, 'IYYY-"W"IW')
    ELSE to_char(v_min_date + (8 - extract(isodow FROM v_min_date))::int, 'IYYY-"W"IW')
  END;
  v_last_full_week := CASE
    WHEN v_max_date IS NULL THEN NULL
    WHEN extract(isodow FROM v_max_date) = 7 THEN to_char(v_max_date, 'IYYY-"W"IW')
    ELSE to_char(v_max_date - extract(isodow FROM v_max_date)::int, 'IYYY-"W"IW')
  END;
  v_first_full_quarter := CASE
    WHEN v_min_date IS NULL THEN NULL
    WHEN v_min_date = date_trunc('quarter', v_min_date)::date
         THEN extract(year FROM v_min_date)::int || '-Q' || extract(quarter FROM v_min_date)::int
    ELSE (WITH next_q AS (SELECT date_trunc('quarter', v_min_date) + interval '3 months' AS d)
          SELECT extract(year FROM d)::int || '-Q' || extract(quarter FROM d)::int FROM next_q)
  END;
  v_last_full_quarter := CASE
    WHEN v_max_date IS NULL THEN NULL
    WHEN v_max_date = (date_trunc('quarter', v_max_date) + interval '3 months - 1 day')::date
         THEN extract(year FROM v_max_date)::int || '-Q' || extract(quarter FROM v_max_date)::int
    ELSE (WITH prev_q AS (SELECT date_trunc('quarter', v_max_date) - interval '1 day' AS d)
          SELECT extract(year FROM d)::int || '-Q' || extract(quarter FROM d)::int FROM prev_q)
  END;

  SELECT jsonb_build_object(
    'totalInvoices',  v_invoice_count,
    'totalCNs',       v_cn_count,
    'totalSuppliers', (SELECT count(DISTINCT supplier_identifier) FROM _bsm),
    'currencies',     COALESCE((SELECT jsonb_agg(DISTINCT ccy ORDER BY ccy) FROM _bsm), '[]'::jsonb),
    'dateRangeMin',   v_min_date,
    'dateRangeMax',   v_max_date,
    'years',          COALESCE(to_jsonb(v_years), '[]'::jsonb),
    'firstFullMonth', v_first_full_month,
    'lastFullMonth',  v_last_full_month,
    'firstFullWeek',  v_first_full_week,
    'lastFullWeek',   v_last_full_week
  ) INTO v_overall;

  -- ALL data → supplier stats + totals
  DROP TABLE IF EXISTS _bsm_p;
  CREATE TEMP TABLE _bsm_p ON COMMIT DROP AS
  SELECT b.*, p.period_key
  FROM _bsm b
  CROSS JOIN LATERAL (
    SELECT unnest(ARRAY[
      'all',
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '12 months' THEN '12m' END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '6 months'  THEN '6m'  END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '3 months'  THEN '3m'  END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '1 month'   THEN '1m'  END,
      b.yr::text
    ]) AS period_key
  ) p
  WHERE p.period_key IS NOT NULL;
  CREATE INDEX _bsm_p_idx ON _bsm_p(period_key, ccy, supplier_identifier);

  -- FULL MONTHS → charts
  DROP TABLE IF EXISTS _bsm_full_p;
  CREATE TEMP TABLE _bsm_full_p ON COMMIT DROP AS
  SELECT b.*, p.period_key
  FROM _bsm b
  CROSS JOIN LATERAL (
    SELECT unnest(ARRAY[
      'all',
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '12 months' THEN '12m' END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '6 months'  THEN '6m'  END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '3 months'  THEN '3m'  END,
      CASE WHEN b.last_invoice_in_month > v_max_date - interval '1 month'   THEN '1m'  END,
      b.yr::text
    ]) AS period_key
  ) p
  WHERE p.period_key IS NOT NULL
    AND (v_first_full_month IS NULL OR b.ym >= v_first_full_month)
    AND (v_last_full_month  IS NULL OR b.ym <= v_last_full_month);
  CREATE INDEX _bsm_full_p_idx ON _bsm_full_p(period_key, ccy, supplier_identifier);

  DROP TABLE IF EXISTS _sup_stats;
  CREATE TEMP TABLE _sup_stats ON COMMIT DROP AS
  SELECT
    period_key, ccy, supplier_identifier AS sid,
    max(supplier_name) AS sname,
    sum(invoice_count)::int AS invoice_count,
    sum(total_spend)::numeric AS total_spend,
    max(max_amount)::numeric AS max_amount,
    min(first_invoice_in_month) AS first_invoice,
    max(last_invoice_in_month) AS last_invoice,
    sum(paid_count)::int AS paid_count,
    sum(unpaid_count)::int AS unpaid_count,
    sum(sum_dpd)::numeric AS sum_dpd,
    sum(dpd_sample_size)::int AS dpd_sample_size,
    sum(on_time_count)::int AS on_time_count,
    sum(late_count)::int AS late_count,
    sum(very_late_count)::int AS very_late_count,
    sum(late_1_14_count)::int    AS late_1_14_count,
    sum(late_15_30_count)::int   AS late_15_30_count,
    sum(late_31_60_count)::int   AS late_31_60_count,
    sum(late_61_plus_count)::int AS late_61_plus_count,
    sum(sum_days_to_paid)::numeric AS sum_days_to_paid,
    sum(sum_stated_term)::numeric AS sum_stated_term,
    sum(stated_term_n)::int AS stated_term_n,
    sum(cn_count)::int AS cn_count,
    sum(cn_total)::numeric AS cn_total,
    sum(short_pay_count)::int AS short_pay_count,
    sum(short_pay_amount)::numeric AS short_pay_amount,
    sum(settled_count)::int AS settled_count,
    sum(rejected_count)::int AS rejected_count,
    sum(rejected_amount)::numeric AS rejected_amount,
    -- Dilution component 4, per supplier.
    sum(cancelled_count)::int AS cancelled_count,
    sum(cancelled_amount)::numeric AS cancelled_amount,
    sum(stale_count)::int AS stale_count,
    sum(stale_amount)::numeric AS stale_amount,
    sum(outstanding_dollar_days)::numeric AS outstanding_dd,
    count(DISTINCT ym) FILTER (WHERE invoice_count > 0)::int AS active_months
  FROM _bsm_p
  GROUP BY period_key, ccy, supplier_identifier;
  CREATE INDEX _sup_stats_idx ON _sup_stats(period_key, ccy, sid);

  DROP TABLE IF EXISTS _sup_monthly_json;
  CREATE TEMP TABLE _sup_monthly_json ON COMMIT DROP AS
  SELECT
    period_key, ccy, supplier_identifier AS sid,
    jsonb_object_agg(ym, invoice_count ORDER BY ym) FILTER (WHERE invoice_count > 0) AS monthly_count,
    jsonb_object_agg(ym, round(total_spend, 2) ORDER BY ym) FILTER (WHERE invoice_count > 0) AS monthly_amount
  FROM _bsm_p
  GROUP BY period_key, ccy, supplier_identifier;
  CREATE INDEX _sup_monthly_json_idx ON _sup_monthly_json(period_key, ccy, sid);

  DROP TABLE IF EXISTS _ccy_totals;
  CREATE TEMP TABLE _ccy_totals ON COMMIT DROP AS
  SELECT period_key, ccy,
    sum(invoice_count)::int   AS invoice_count,
    sum(total_spend)::numeric AS total_spend,
    max(max_amount)::numeric  AS max_amount,
    sum(sum_dpd)::numeric     AS sum_dpd,
    sum(dpd_sample_size)::int AS dpd_sample_size,
    sum(on_time_count)::int   AS on_time_count,
    sum(late_count)::int      AS late_count,
    sum(late_1_14_count)::int    AS late_1_14_count,
    sum(late_15_30_count)::int   AS late_15_30_count,
    sum(late_31_60_count)::int   AS late_31_60_count,
    sum(late_61_plus_count)::int AS late_61_plus_count,
    sum(paid_count)::int      AS paid_count,
    sum(sum_days_to_paid)::numeric AS sum_days_to_paid,
    sum(sum_stated_term)::numeric  AS sum_stated_term,
    sum(stated_term_n)::int        AS stated_term_n,
    sum(cn_count)::int        AS cn_count,
    sum(cn_total)::numeric    AS cn_total,
    sum(short_pay_count)::int    AS short_pay_count,
    sum(short_pay_amount)::numeric AS short_pay_amount,
    sum(settled_count)::int      AS settled_count,
    sum(rejected_count)::int     AS rejected_count,
    sum(rejected_amount)::numeric AS rejected_amount,
    -- Dilution component 4, and the two inputs to the AP-float display gate.
    sum(cancelled_count)::int     AS cancelled_count,
    sum(cancelled_amount)::numeric AS cancelled_amount,
    sum(mature_invoice_count)::int  AS mature_invoice_count,
    sum(mature_resolved_count)::int AS mature_resolved_count,
    sum(stale_count)::int        AS stale_count,
    sum(stale_amount)::numeric   AS stale_amount,
    sum(no_due_count)::int       AS no_due_count,
    sum(no_due_spend)::numeric   AS no_due_spend,
    sum(outstanding_dollar_days)::numeric AS outstanding_dd
  FROM _bsm_p GROUP BY period_key, ccy;

  -- Payment-terms distribution per (period, ccy): merge the per-supplier-month
  -- term_hist maps, bucket exact day-counts into named bands for display, and
  -- derive BOTH weighted averages from the FULL exact set (not the bands).
  DROP TABLE IF EXISTS _ccy_terms;
  CREATE TEMP TABLE _ccy_terms ON COMMIT DROP AS
  WITH per_term AS (
    SELECT p.period_key, p.ccy, (e.key)::int AS term,
           sum((e.value->>'n')::int)         AS n,
           sum((e.value->>'spend')::numeric) AS sp,
           sum(COALESCE((e.value->>'dpdN')::int, 0))        AS dpd_n,
           sum(COALESCE((e.value->>'dpdWSum')::numeric, 0)) AS dpd_wsum,
           sum(COALESCE((e.value->>'dpdWAmt')::numeric, 0)) AS dpd_wamt
    FROM _bsm_p p, LATERAL jsonb_each(p.term_hist) AS e
    WHERE p.term_hist IS NOT NULL AND p.term_hist <> '{}'::jsonb
    GROUP BY p.period_key, p.ccy, (e.key)::int
  ),
  banded AS (
    SELECT period_key, ccy,
      CASE
        WHEN term <= 7  THEN 1 WHEN term <= 14 THEN 2 WHEN term <= 30 THEN 3
        WHEN term <= 45 THEN 4 WHEN term <= 60 THEN 5 WHEN term <= 90 THEN 6
        ELSE 7
      END AS band_sort,
      sum(n) AS n, sum(sp) AS sp,
      sum(dpd_n) AS dpd_n, sum(dpd_wsum) AS dpd_wsum, sum(dpd_wamt) AS dpd_wamt
    FROM per_term
    GROUP BY period_key, ccy,
      CASE
        WHEN term <= 7  THEN 1 WHEN term <= 14 THEN 2 WHEN term <= 30 THEN 3
        WHEN term <= 45 THEN 4 WHEN term <= 60 THEN 5 WHEN term <= 90 THEN 6
        ELSE 7
      END
  ),
  dist AS (
    SELECT period_key, ccy,
      jsonb_agg(jsonb_build_object(
        'band', CASE band_sort
          WHEN 1 THEN 'Net <=7'   WHEN 2 THEN 'Net 8-14'  WHEN 3 THEN 'Net 15-30'
          WHEN 4 THEN 'Net 31-45' WHEN 5 THEN 'Net 46-60' WHEN 6 THEN 'Net 61-90'
          ELSE 'Net 90+'
        END,
        'sortKey',  band_sort,
        'invoices', n,
        'spend',    round(sp, 2),
        'daysBeyondTerms', CASE WHEN dpd_wamt > 0 THEN round(dpd_wsum / dpd_wamt, 1) ELSE NULL END,
        'paidInvoices',    dpd_n
      ) ORDER BY band_sort) AS distribution
    FROM banded
    GROUP BY period_key, ccy
  ),
  avgs AS (
    SELECT period_key, ccy,
      CASE WHEN sum(n)  > 0 THEN round(sum(term * n)::numeric  / sum(n),  1) ELSE NULL END AS count_weighted_avg,
      CASE WHEN sum(sp) > 0 THEN round(sum(term * sp)::numeric / sum(sp), 1) ELSE NULL END AS value_weighted_avg
    FROM per_term
    GROUP BY period_key, ccy
  )
  SELECT d.period_key, d.ccy, d.distribution, a.count_weighted_avg, a.value_weighted_avg
  FROM dist d JOIN avgs a ON a.period_key = d.period_key AND a.ccy = d.ccy;
  CREATE INDEX _ccy_terms_idx ON _ccy_terms(period_key, ccy);

  -- Monthly volume + dilution — FULL MONTHS
  DROP TABLE IF EXISTS _ts_monthly_vol;
  CREATE TEMP TABLE _ts_monthly_vol ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', ym, 'invoiceCount', cnt, 'totalSpend', round(spend, 2)) ORDER BY ym) AS volume
  FROM (SELECT period_key, ccy, ym, sum(invoice_count)::int AS cnt, sum(total_spend)::numeric AS spend
        FROM _bsm_full_p WHERE invoice_count > 0 GROUP BY period_key, ccy, ym) z
  GROUP BY period_key, ccy;

  -- All four components. combinedRate is the total; adverseRate drops
  -- supplier-side cancellation and is the series to plot against a buyer.
  DROP TABLE IF EXISTS _ts_monthly_dil;
  CREATE TEMP TABLE _ts_monthly_dil ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', ym, 'invTotal', round(inv_total, 2),
      'cnTotal',        round(cn_amount, 2),
      'shortPayTotal',  round(sp_amount, 2),
      'rejectedTotal',  round(rej_amount, 2),
      'cancelledTotal', round(canc_amount, 2),
      'rate',          CASE WHEN inv_total > 0 THEN cn_amount / inv_total ELSE 0 END,
      'shortPayRate',  CASE WHEN inv_total > 0 THEN sp_amount / inv_total ELSE 0 END,
      'rejectedRate',  CASE WHEN inv_total > 0 THEN rej_amount / inv_total ELSE 0 END,
      'cancelledRate', CASE WHEN inv_total > 0 THEN canc_amount / inv_total ELSE 0 END,
      'combinedRate',  CASE WHEN inv_total > 0 THEN (cn_amount + sp_amount + rej_amount + canc_amount) / inv_total ELSE 0 END,
      'adverseRate',   CASE WHEN inv_total > 0 THEN (cn_amount + sp_amount + rej_amount) / inv_total ELSE 0 END) ORDER BY ym) AS dilution
  FROM (SELECT period_key, ccy, ym, sum(total_spend)::numeric AS inv_total, sum(cn_total)::numeric AS cn_amount,
               sum(short_pay_amount)::numeric AS sp_amount,
               sum(rejected_amount)::numeric  AS rej_amount,
               sum(cancelled_amount)::numeric AS canc_amount
        FROM _bsm_full_p GROUP BY period_key, ccy, ym) z
  GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _bcpp;
  CREATE TEMP TABLE _bcpp ON COMMIT DROP AS
  SELECT * FROM buyer_currency_paid_period WHERE upload_id = p_upload_id;
  CREATE INDEX _bcpp_idx ON _bcpp(ccy, period_kind, period_key);

  DROP TABLE IF EXISTS _bcpp_p;
  CREATE TEMP TABLE _bcpp_p ON COMMIT DROP AS
  SELECT b.*, p.period_key AS pkey
  FROM _bcpp b
  CROSS JOIN LATERAL (
    SELECT unnest(ARRAY[
      'all',
      CASE WHEN b.bucket_last_paid > v_max_date - interval '12 months' THEN '12m' END,
      CASE WHEN b.bucket_last_paid > v_max_date - interval '6 months'  THEN '6m'  END,
      CASE WHEN b.bucket_last_paid > v_max_date - interval '3 months'  THEN '3m'  END,
      CASE WHEN b.bucket_last_paid > v_max_date - interval '1 month'   THEN '1m'  END,
      extract(year FROM b.bucket_last_paid)::text
    ]) AS period_key
  ) p
  WHERE p.period_key IS NOT NULL;
  CREATE INDEX _bcpp_p_idx ON _bcpp_p(pkey, ccy, period_kind);

  DROP TABLE IF EXISTS _ts_monthly_pmt;
  CREATE TEMP TABLE _ts_monthly_pmt ON COMMIT DROP AS
  SELECT pkey AS period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', period_key, 'paidCount', paid_count, 'medianDpd', NULL,
      'avgDpd', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_dpd / paid_count, 1) ELSE NULL END,
      'avgDaysToPaid', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_days_to_paid / paid_count, 1) ELSE NULL END,
      'avgStatedTerm', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_stated_term / paid_count, 1) ELSE NULL END,
      'onTimePct', CASE WHEN paid_count >= v_min_paid_sample THEN on_time_count::numeric / paid_count ELSE NULL END
    ) ORDER BY period_key) AS payments
  FROM _bcpp_p
  WHERE period_kind = 'M'
    AND (v_first_full_month IS NULL OR period_key >= v_first_full_month)
    AND (v_last_full_month  IS NULL OR period_key <= v_last_full_month)
  GROUP BY pkey, ccy;

  DROP TABLE IF EXISTS _ts_quarterly_pmt;
  CREATE TEMP TABLE _ts_quarterly_pmt ON COMMIT DROP AS
  SELECT pkey AS period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', period_key, 'paidCount', paid_count, 'medianDpd', NULL,
      'avgDpd', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_dpd / paid_count, 1) ELSE NULL END,
      'avgDaysToPaid', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_days_to_paid / paid_count, 1) ELSE NULL END,
      'avgStatedTerm', CASE WHEN paid_count >= v_min_paid_sample THEN round(sum_stated_term / paid_count, 1) ELSE NULL END,
      'onTimePct', CASE WHEN paid_count >= v_min_paid_sample THEN on_time_count::numeric / paid_count ELSE NULL END
    ) ORDER BY period_key) AS payments
  FROM _bcpp_p
  WHERE period_kind = 'Q'
    AND (v_first_full_quarter IS NULL OR period_key >= v_first_full_quarter)
    AND (v_last_full_quarter  IS NULL OR period_key <= v_last_full_quarter)
  GROUP BY pkey, ccy;

  DROP TABLE IF EXISTS _bcw;
  CREATE TEMP TABLE _bcw ON COMMIT DROP AS
  SELECT * FROM buyer_currency_weekly
  WHERE upload_id = p_upload_id
    AND (v_first_full_week IS NULL OR yw >= v_first_full_week)
    AND (v_last_full_week  IS NULL OR yw <= v_last_full_week);
  CREATE INDEX _bcw_ccy ON _bcw(ccy);

  DROP TABLE IF EXISTS _bcw_p;
  CREATE TEMP TABLE _bcw_p ON COMMIT DROP AS
  SELECT b.*, p.period_key
  FROM _bcw b
  CROSS JOIN LATERAL (
    SELECT unnest(ARRAY[
      'all',
      CASE WHEN b.bucket_last_date > v_max_date - interval '12 months' THEN '12m' END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '6 months'  THEN '6m'  END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '3 months'  THEN '3m'  END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '1 month'   THEN '1m'  END,
      b.yr::text
    ]) AS period_key
  ) p
  WHERE p.period_key IS NOT NULL;
  CREATE INDEX _bcw_p_idx ON _bcw_p(period_key, ccy);

  DROP TABLE IF EXISTS _ts_weekly_vol;
  CREATE TEMP TABLE _ts_weekly_vol ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', yw, 'invoiceCount', invoice_count, 'totalSpend', round(total_spend, 2)) ORDER BY yw) AS volume
  FROM _bcw_p WHERE invoice_count > 0 GROUP BY period_key, ccy;

  -- Weekly now matches monthly and quarterly. COALESCE throughout because a
  -- weekly row created by the credit-note or paid-date inserts carries no
  -- invoice-side figures at all.
  DROP TABLE IF EXISTS _ts_weekly_dil;
  CREATE TEMP TABLE _ts_weekly_dil ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', yw, 'invTotal', round(total_spend, 2), 'cnTotal', round(cn_total, 2),
      'shortPayTotal',  round(COALESCE(short_pay_amount, 0), 2),
      'rejectedTotal',  round(COALESCE(rejected_amount, 0), 2),
      'cancelledTotal', round(COALESCE(cancelled_amount, 0), 2),
      'rate',          CASE WHEN total_spend > 0 THEN cn_total / total_spend ELSE 0 END,
      'shortPayRate',  CASE WHEN total_spend > 0 THEN COALESCE(short_pay_amount, 0) / total_spend ELSE 0 END,
      'rejectedRate',  CASE WHEN total_spend > 0 THEN COALESCE(rejected_amount, 0)  / total_spend ELSE 0 END,
      'cancelledRate', CASE WHEN total_spend > 0 THEN COALESCE(cancelled_amount, 0) / total_spend ELSE 0 END,
      'combinedRate',  CASE WHEN total_spend > 0 THEN (COALESCE(cn_total, 0) + COALESCE(short_pay_amount, 0) + COALESCE(rejected_amount, 0) + COALESCE(cancelled_amount, 0)) / total_spend ELSE 0 END,
      'adverseRate',   CASE WHEN total_spend > 0 THEN (COALESCE(cn_total, 0) + COALESCE(short_pay_amount, 0) + COALESCE(rejected_amount, 0)) / total_spend ELSE 0 END) ORDER BY yw) AS dilution
  FROM _bcw_p GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _ts_weekly_pmt;
  CREATE TEMP TABLE _ts_weekly_pmt ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', yw, 'paidCount', paid_count_pw, 'medianDpd', NULL,
      'avgDpd', CASE WHEN dpd_sample_pw >= v_min_paid_sample THEN round(sum_dpd_pw / dpd_sample_pw, 1) ELSE NULL END,
      'avgDaysToPaid', CASE WHEN paid_count_pw >= v_min_paid_sample THEN round(sum_days_to_paid_pw / paid_count_pw, 1) ELSE NULL END,
      'avgStatedTerm', CASE WHEN paid_count_pw >= v_min_paid_sample THEN round(sum_stated_term_pw / paid_count_pw, 1) ELSE NULL END,
      'onTimePct', CASE WHEN dpd_sample_pw >= v_min_paid_sample THEN on_time_count_pw::numeric / dpd_sample_pw ELSE NULL END
    ) ORDER BY yw) AS payments
  FROM _bcw_p WHERE dpd_sample_pw > 0 GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _ts_quarterly_vol;
  CREATE TEMP TABLE _ts_quarterly_vol ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', yq, 'invoiceCount', cnt, 'totalSpend', round(spend, 2)) ORDER BY yq) AS volume
  FROM (SELECT period_key, ccy, yq, sum(invoice_count)::int AS cnt, sum(total_spend)::numeric AS spend
        FROM _bsm_full_p
        WHERE invoice_count > 0 AND yq IS NOT NULL
          AND (v_first_full_quarter IS NULL OR yq >= v_first_full_quarter)
          AND (v_last_full_quarter  IS NULL OR yq <= v_last_full_quarter)
        GROUP BY period_key, ccy, yq) z
  GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _ts_quarterly_dil;
  CREATE TEMP TABLE _ts_quarterly_dil ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_agg(jsonb_build_object('bucket', yq, 'invTotal', round(inv_total, 2), 'cnTotal', round(cn_amount, 2),
      'shortPayTotal',  round(sp_amount, 2),
      'rejectedTotal',  round(rej_amount, 2),
      'cancelledTotal', round(canc_amount, 2),
      'rate',          CASE WHEN inv_total > 0 THEN cn_amount / inv_total ELSE 0 END,
      'shortPayRate',  CASE WHEN inv_total > 0 THEN sp_amount / inv_total ELSE 0 END,
      'rejectedRate',  CASE WHEN inv_total > 0 THEN rej_amount / inv_total ELSE 0 END,
      'cancelledRate', CASE WHEN inv_total > 0 THEN canc_amount / inv_total ELSE 0 END,
      'combinedRate',  CASE WHEN inv_total > 0 THEN (cn_amount + sp_amount + rej_amount + canc_amount) / inv_total ELSE 0 END,
      'adverseRate',   CASE WHEN inv_total > 0 THEN (cn_amount + sp_amount + rej_amount) / inv_total ELSE 0 END) ORDER BY yq) AS dilution
  FROM (SELECT period_key, ccy, yq, sum(total_spend)::numeric AS inv_total, sum(cn_total)::numeric AS cn_amount,
               sum(short_pay_amount)::numeric AS sp_amount,
               sum(rejected_amount)::numeric  AS rej_amount,
               sum(cancelled_amount)::numeric AS canc_amount
        FROM _bsm_full_p
        WHERE yq IS NOT NULL
          AND (v_first_full_quarter IS NULL OR yq >= v_first_full_quarter)
          AND (v_last_full_quarter  IS NULL OR yq <= v_last_full_quarter)
        GROUP BY period_key, ccy, yq) z
  GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _topN;
  CREATE TEMP TABLE _topN ON COMMIT DROP AS
  SELECT period_key, ccy,
    array_agg(sid ORDER BY total_spend DESC) AS top_sids,
    array_agg(sname ORDER BY total_spend DESC) AS top_names
  FROM (SELECT period_key, ccy, sid, sname, total_spend,
          row_number() OVER (PARTITION BY period_key, ccy ORDER BY total_spend DESC) AS rn
        FROM _sup_stats) z
  WHERE rn <= v_top_n
  GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _ts_monthly_conc;
  CREATE TEMP TABLE _ts_monthly_conc ON COMMIT DROP AS
  WITH bucket_totals AS (
    SELECT period_key, ccy, ym, sum(total_spend)::numeric AS bucket_total
    FROM _bsm_full_p GROUP BY period_key, ccy, ym
  ),
  topN_in_bucket AS (
    SELECT b.period_key, b.ccy, b.ym, b.supplier_identifier AS sid, t.top_names,
      sum(b.total_spend)::numeric AS sid_spend, array_position(t.top_sids, b.supplier_identifier) AS pos
    FROM _bsm_full_p b JOIN _topN t ON t.period_key = b.period_key AND t.ccy = b.ccy
    WHERE b.supplier_identifier = ANY(t.top_sids)
    GROUP BY b.period_key, b.ccy, b.ym, b.supplier_identifier, t.top_names, t.top_sids
  ),
  shares_per_bucket AS (
    SELECT tb.period_key, tb.ccy, tb.ym, tb.top_names,
      jsonb_object_agg(COALESCE(tb.top_names[tb.pos], '?'),
        CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_shares,
      sum(CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_total
    FROM topN_in_bucket tb JOIN bucket_totals bt USING (period_key, ccy, ym)
    GROUP BY tb.period_key, tb.ccy, tb.ym, tb.top_names
  )
  SELECT period_key, ccy, top_names,
    jsonb_agg(jsonb_build_object('bucket', ym, 'shares', top_shares, 'otherPct', GREATEST(0, 1 - top_total)) ORDER BY ym) AS series
  FROM shares_per_bucket GROUP BY period_key, ccy, top_names;

  DROP TABLE IF EXISTS _ts_quarterly_conc;
  CREATE TEMP TABLE _ts_quarterly_conc ON COMMIT DROP AS
  WITH bucket_totals AS (
    SELECT period_key, ccy, yq, sum(total_spend)::numeric AS bucket_total
    FROM _bsm_full_p
    WHERE yq IS NOT NULL
      AND (v_first_full_quarter IS NULL OR yq >= v_first_full_quarter)
      AND (v_last_full_quarter  IS NULL OR yq <= v_last_full_quarter)
    GROUP BY period_key, ccy, yq
  ),
  topN_in_bucket AS (
    SELECT b.period_key, b.ccy, b.yq, b.supplier_identifier AS sid, t.top_names,
      sum(b.total_spend)::numeric AS sid_spend, array_position(t.top_sids, b.supplier_identifier) AS pos
    FROM _bsm_full_p b JOIN _topN t ON t.period_key = b.period_key AND t.ccy = b.ccy
    WHERE b.yq IS NOT NULL
      AND (v_first_full_quarter IS NULL OR b.yq >= v_first_full_quarter)
      AND (v_last_full_quarter  IS NULL OR b.yq <= v_last_full_quarter)
      AND b.supplier_identifier = ANY(t.top_sids)
    GROUP BY b.period_key, b.ccy, b.yq, b.supplier_identifier, t.top_names, t.top_sids
  ),
  shares_per_bucket AS (
    SELECT tb.period_key, tb.ccy, tb.yq, tb.top_names,
      jsonb_object_agg(COALESCE(tb.top_names[tb.pos], '?'),
        CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_shares,
      sum(CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_total
    FROM topN_in_bucket tb JOIN bucket_totals bt USING (period_key, ccy, yq)
    GROUP BY tb.period_key, tb.ccy, tb.yq, tb.top_names
  )
  SELECT period_key, ccy, top_names,
    jsonb_agg(jsonb_build_object('bucket', yq, 'shares', top_shares, 'otherPct', GREATEST(0, 1 - top_total)) ORDER BY yq) AS series
  FROM shares_per_bucket GROUP BY period_key, ccy, top_names;

  DROP TABLE IF EXISTS _bi_weekly_sup;
  CREATE TEMP TABLE _bi_weekly_sup ON COMMIT DROP AS
  SELECT upper(currency) AS ccy, to_char(invoice_date, 'IYYY-"W"IW') AS yw,
    supplier_identifier, sum(amount)::numeric AS spend, max(invoice_date) AS bucket_last_date
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE
    AND supplier_identifier IS NOT NULL AND currency IS NOT NULL AND invoice_date IS NOT NULL
  GROUP BY upper(currency), to_char(invoice_date, 'IYYY-"W"IW'), supplier_identifier
  HAVING (v_first_full_week IS NULL OR to_char(max(invoice_date), 'IYYY-"W"IW') >= v_first_full_week)
     AND (v_last_full_week  IS NULL OR to_char(max(invoice_date), 'IYYY-"W"IW') <= v_last_full_week);
  CREATE INDEX _bi_weekly_sup_idx ON _bi_weekly_sup(ccy, yw);

  DROP TABLE IF EXISTS _bi_weekly_sup_p;
  CREATE TEMP TABLE _bi_weekly_sup_p ON COMMIT DROP AS
  SELECT b.*, p.period_key
  FROM _bi_weekly_sup b
  CROSS JOIN LATERAL (
    SELECT unnest(ARRAY[
      'all',
      CASE WHEN b.bucket_last_date > v_max_date - interval '12 months' THEN '12m' END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '6 months'  THEN '6m'  END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '3 months'  THEN '3m'  END,
      CASE WHEN b.bucket_last_date > v_max_date - interval '1 month'   THEN '1m'  END,
      extract(isoyear FROM b.bucket_last_date)::text
    ]) AS period_key
  ) p
  WHERE p.period_key IS NOT NULL;
  CREATE INDEX _bi_weekly_sup_p_idx ON _bi_weekly_sup_p(period_key, ccy, yw);

  DROP TABLE IF EXISTS _ts_weekly_conc;
  CREATE TEMP TABLE _ts_weekly_conc ON COMMIT DROP AS
  WITH bucket_totals AS (
    SELECT period_key, ccy, yw, sum(spend)::numeric AS bucket_total
    FROM _bi_weekly_sup_p GROUP BY period_key, ccy, yw
  ),
  topN_in_bucket AS (
    SELECT b.period_key, b.ccy, b.yw, b.supplier_identifier AS sid, t.top_names,
      sum(b.spend)::numeric AS sid_spend, array_position(t.top_sids, b.supplier_identifier) AS pos
    FROM _bi_weekly_sup_p b JOIN _topN t ON t.period_key = b.period_key AND t.ccy = b.ccy
    WHERE b.supplier_identifier = ANY(t.top_sids)
    GROUP BY b.period_key, b.ccy, b.yw, b.supplier_identifier, t.top_names, t.top_sids
  ),
  shares_per_bucket AS (
    SELECT tb.period_key, tb.ccy, tb.yw, tb.top_names,
      jsonb_object_agg(COALESCE(tb.top_names[tb.pos], '?'),
        CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_shares,
      sum(CASE WHEN bt.bucket_total > 0 THEN tb.sid_spend / bt.bucket_total ELSE 0 END) AS top_total
    FROM topN_in_bucket tb JOIN bucket_totals bt USING (period_key, ccy, yw)
    GROUP BY tb.period_key, tb.ccy, tb.yw, tb.top_names
  )
  SELECT period_key, ccy, top_names,
    jsonb_agg(jsonb_build_object('bucket', yw, 'shares', top_shares, 'otherPct', GREATEST(0, 1 - top_total)) ORDER BY yw) AS series
  FROM shares_per_bucket GROUP BY period_key, ccy, top_names;

  DROP TABLE IF EXISTS _ccy_volume;
  CREATE TEMP TABLE _ccy_volume ON COMMIT DROP AS
  SELECT period_key, ccy,
    jsonb_object_agg(ym, jsonb_build_object('count', cnt, 'amount', round(spend, 2)) ORDER BY ym) AS volume
  FROM (SELECT period_key, ccy, ym, sum(invoice_count)::int AS cnt, sum(total_spend)::numeric AS spend
        FROM _bsm_p WHERE invoice_count > 0 GROUP BY period_key, ccy, ym) z
  GROUP BY period_key, ccy;

  DROP TABLE IF EXISTS _per_period_ccy;
  CREATE TEMP TABLE _per_period_ccy ON COMMIT DROP AS
  SELECT
    ct.period_key, ct.ccy,
    jsonb_build_object(
      'totals', jsonb_build_object(
        'invoiceCount',  ct.invoice_count,
        'totalSpend',    round(ct.total_spend, 2),
        'maxInvoiceAmount', round(ct.max_amount, 2),
        'cnCount',       ct.cn_count,
        'totalCNs',      round(ct.cn_total, 2),
        'supplierCount', (SELECT count(*) FROM _sup_stats ss WHERE ss.ccy = ct.ccy AND ss.period_key = ct.period_key AND ss.invoice_count > 0),
        'avgDaysPastDue', CASE WHEN ct.dpd_sample_size > 0 THEN round(ct.sum_dpd / ct.dpd_sample_size, 1) ELSE NULL END,
        'avgDaysToPaid',     CASE WHEN ct.paid_count   > 0 THEN round(ct.sum_days_to_paid / ct.paid_count, 1) ELSE NULL END,
        'avgStatedTermDays', CASE WHEN ct.stated_term_n > 0 THEN round(ct.sum_stated_term / ct.stated_term_n, 1) ELSE NULL END,
        'paymentTerms', jsonb_build_object(
          'distribution',         COALESCE((SELECT distribution        FROM _ccy_terms x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'countWeightedAvgDays', (SELECT count_weighted_avg FROM _ccy_terms x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key),
          'valueWeightedAvgDays', (SELECT value_weighted_avg FROM _ccy_terms x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key),
          'noDueDateCount',       ct.no_due_count,
          'noDueDateSpend',       round(ct.no_due_spend, 2)
        ),
        'medianDaysPastDue', NULL,
        'onTimePct',     CASE WHEN ct.dpd_sample_size > 0 THEN ct.on_time_count::numeric / ct.dpd_sample_size ELSE NULL END,
        'latePct',       CASE WHEN ct.dpd_sample_size > 0 THEN ct.late_count::numeric    / ct.dpd_sample_size ELSE NULL END,
        'latenessDistribution', jsonb_build_object(
          'onTimeOrEarly', ct.on_time_count,
          'd1to14',        ct.late_1_14_count,
          'd15to30',       ct.late_15_30_count,
          'd31to60',       ct.late_31_60_count,
          'd61plus',       ct.late_61_plus_count,
          'noDueDate',     GREATEST(ct.paid_count - ct.dpd_sample_size, 0),
          'sample',        ct.dpd_sample_size,
          'paidCount',     ct.paid_count
        ),
        'dilutionRate',  CASE WHEN ct.total_spend > 0 THEN ct.cn_total / ct.total_spend ELSE 0 END,
        'shortPayAmount', round(ct.short_pay_amount, 2),
        'shortPayCount',  ct.short_pay_count,
        'settledCount',   ct.settled_count,
        'rejectedCount',  ct.rejected_count,
        'rejectedAmount', round(ct.rejected_amount, 2),
        'rejectionRate',  CASE WHEN ct.total_spend > 0 THEN ct.rejected_amount / ct.total_spend ELSE 0 END,
        'rejectionCountRate', CASE WHEN ct.invoice_count > 0 THEN ct.rejected_count::numeric / ct.invoice_count ELSE 0 END,
        -- Dilution component 4. Supplier-driven by rule: real leakage, so it
        -- sits in combinedDilutionRate, but it is never the buyer's failing so
        -- it is absent from adverseDilutionRate — which is the figure every
        -- severity, flag and league sort in the app actually reads. Collapse
        -- the two and a supplier withdrawing their own duplicate invoice
        -- starts generating red flags against a buyer who did nothing.
        'cancelledCount',   ct.cancelled_count,
        'cancelledAmount',  round(ct.cancelled_amount, 2),
        'cancellationRate', CASE WHEN ct.total_spend > 0 THEN ct.cancelled_amount / ct.total_spend ELSE 0 END,
        'implicitDilutionRate', CASE WHEN ct.total_spend > 0 THEN ct.short_pay_amount / ct.total_spend ELSE 0 END,
        'combinedDilutionRate', CASE WHEN ct.total_spend > 0 THEN (ct.cn_total + ct.short_pay_amount + ct.rejected_amount + ct.cancelled_amount) / ct.total_spend ELSE 0 END,
        'adverseDilutionRate',  CASE WHEN ct.total_spend > 0 THEN (ct.cn_total + ct.short_pay_amount + ct.rejected_amount) / ct.total_spend ELSE 0 END,
        -- AP-float display gate. Coverage over MATURE invoices only (due more
        -- than 60 days before the file horizon), because scoring it across all
        -- invoices would penalise recent data. NULL when there is no mature
        -- population at all, which the app reads as "fall back to the naive
        -- figure" rather than as zero coverage.
        'matureInvoiceCount',  ct.mature_invoice_count,
        'matureResolvedCount', ct.mature_resolved_count,
        'matureCoveragePct',   CASE WHEN ct.mature_invoice_count > 0 THEN ct.mature_resolved_count::numeric / ct.mature_invoice_count ELSE NULL END,
        'staleCount',    ct.stale_count,
        'staleAmount',   round(ct.stale_amount, 2),
        'stalePct',      CASE WHEN ct.total_spend > 0 THEN ct.stale_amount / ct.total_spend ELSE 0 END,
        'apOutstandingAvg', CASE WHEN ct.period_key = 'all' THEN round(ct.outstanding_dd / GREATEST(v_max_date - v_min_date, 1), 2) ELSE NULL END,
        'apDailySpend',     CASE WHEN ct.period_key = 'all' THEN round(ct.total_spend   / GREATEST(v_max_date - v_min_date, 1), 2) ELSE NULL END,
        'apSpanDays',       CASE WHEN ct.period_key = 'all' THEN GREATEST(v_max_date - v_min_date, 1) ELSE NULL END
      ),
      'suppliers', COALESCE((
        SELECT jsonb_agg(jsonb_build_object(
          'identifier',         ss.sid,
          'name',               ss.sname,
          'invoiceCount',       ss.invoice_count,
          'totalSpend',         round(ss.total_spend, 2),
          'sharePct',           CASE WHEN ct.total_spend > 0 THEN ss.total_spend / ct.total_spend ELSE 0 END,
          'avgInvoiceAmount',   CASE WHEN ss.invoice_count > 0 THEN round(ss.total_spend / ss.invoice_count, 2) ELSE 0 END,
          'maxInvoiceAmount',   round(ss.max_amount, 2),
          'medianInvoiceAmount', NULL,
          'firstInvoice',       ss.first_invoice,
          'lastInvoice',        ss.last_invoice,
          'activeMonths',       ss.active_months,
          'paidCount',          ss.paid_count,
          'unpaidCount',        ss.unpaid_count,
          'paymentCoveragePct', CASE WHEN ss.invoice_count > 0 THEN ss.paid_count::numeric / ss.invoice_count ELSE 0 END,
          'avgDaysPastDue',     CASE WHEN ss.dpd_sample_size > 0 THEN round(ss.sum_dpd / ss.dpd_sample_size, 1) ELSE NULL END,
          'avgDaysToPaid',      CASE WHEN ss.paid_count   > 0 THEN round(ss.sum_days_to_paid / ss.paid_count, 1) ELSE NULL END,
          'avgStatedTermDays',  CASE WHEN ss.stated_term_n > 0 THEN round(ss.sum_stated_term / ss.stated_term_n, 1) ELSE NULL END,
          'medianDaysPastDue',  NULL,
          'onTimePct',          CASE WHEN ss.dpd_sample_size > 0 THEN ss.on_time_count::numeric / ss.dpd_sample_size ELSE NULL END,
          'latePct',            CASE WHEN ss.dpd_sample_size > 0 THEN ss.late_count::numeric    / ss.dpd_sample_size ELSE NULL END,
          'veryLatePct',        CASE WHEN ss.dpd_sample_size > 0 THEN ss.very_late_count::numeric / ss.dpd_sample_size ELSE NULL END,
          'latenessDistribution', jsonb_build_object(
            'onTimeOrEarly', ss.on_time_count,
            'd1to14',        ss.late_1_14_count,
            'd15to30',       ss.late_15_30_count,
            'd31to60',       ss.late_31_60_count,
            'd61plus',       ss.late_61_plus_count,
            'noDueDate',     GREATEST(ss.paid_count - ss.dpd_sample_size, 0),
            'sample',        ss.dpd_sample_size,
            'paidCount',     ss.paid_count
          ),
          'cnCount',            ss.cn_count,
          'cnTotal',            round(ss.cn_total, 2),
          'dilutionRate',       CASE WHEN ss.total_spend > 0 THEN ss.cn_total / ss.total_spend ELSE 0 END,
          'shortPayCount',      ss.short_pay_count,
          'shortPayAmount',     round(ss.short_pay_amount, 2),
          'settledCount',       ss.settled_count,
          'rejectedCount',      ss.rejected_count,
          'rejectedAmount',     round(ss.rejected_amount, 2),
          'rejectionRate',      CASE WHEN ss.total_spend > 0 THEN ss.rejected_amount / ss.total_spend ELSE 0 END,
          -- Same four components per supplier, so supplier dilution still adds
          -- up to the currency total rather than quietly diverging from it.
          'cancelledCount',     ss.cancelled_count,
          'cancelledAmount',    round(ss.cancelled_amount, 2),
          'cancellationRate',   CASE WHEN ss.total_spend > 0 THEN ss.cancelled_amount / ss.total_spend ELSE 0 END,
          'implicitDilutionRate', CASE WHEN ss.total_spend > 0 THEN ss.short_pay_amount / ss.total_spend ELSE 0 END,
          'combinedDilutionRate', CASE WHEN ss.total_spend > 0 THEN (ss.cn_total + ss.short_pay_amount + ss.rejected_amount + ss.cancelled_amount) / ss.total_spend ELSE 0 END,
          'adverseDilutionRate',  CASE WHEN ss.total_spend > 0 THEN (ss.cn_total + ss.short_pay_amount + ss.rejected_amount) / ss.total_spend ELSE 0 END,
          'staleCount',         ss.stale_count,
          'staleAmount',        round(ss.stale_amount, 2),
          'stalePct',           CASE WHEN ss.total_spend > 0 THEN ss.stale_amount / ss.total_spend ELSE 0 END,
          'avgOutstanding',     CASE WHEN ct.period_key = 'all' THEN round(ss.outstanding_dd / GREATEST(v_max_date - v_min_date, 1), 2) ELSE NULL END,
          'monthlyInvoiceCount',  COALESCE(smj.monthly_count,  '{}'::jsonb),
          'monthlyInvoiceAmount', COALESCE(smj.monthly_amount, '{}'::jsonb)
        ) ORDER BY ss.total_spend DESC)
        FROM _sup_stats ss
        LEFT JOIN _sup_monthly_json smj
          ON smj.period_key = ss.period_key AND smj.ccy = ss.ccy AND smj.sid = ss.sid
        WHERE ss.ccy = ct.ccy AND ss.period_key = ct.period_key AND ss.invoice_count > 0
      ), '[]'::jsonb),
      'volumeOverTime', COALESCE((SELECT volume FROM _ccy_volume cv WHERE cv.ccy = ct.ccy AND cv.period_key = ct.period_key), '{}'::jsonb),
      'timeSeries', jsonb_build_object(
        'monthly', jsonb_build_object(
          'volume',   COALESCE((SELECT volume   FROM _ts_monthly_vol x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'dilution', COALESCE((SELECT dilution FROM _ts_monthly_dil x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'payments', COALESCE((SELECT payments FROM _ts_monthly_pmt x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'concentration', jsonb_build_object(
            'topNames', COALESCE((SELECT to_jsonb(top_names) FROM _ts_monthly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
            'series',   COALESCE((SELECT series             FROM _ts_monthly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb)
          )
        ),
        'weekly', jsonb_build_object(
          'volume',   COALESCE((SELECT volume   FROM _ts_weekly_vol x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'dilution', COALESCE((SELECT dilution FROM _ts_weekly_dil x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'payments', COALESCE((SELECT payments FROM _ts_weekly_pmt x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'concentration', jsonb_build_object(
            'topNames', COALESCE((SELECT to_jsonb(top_names) FROM _ts_weekly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
            'series',   COALESCE((SELECT series             FROM _ts_weekly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb)
          )
        ),
        'quarterly', jsonb_build_object(
          'volume',   COALESCE((SELECT volume   FROM _ts_quarterly_vol x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'dilution', COALESCE((SELECT dilution FROM _ts_quarterly_dil x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'payments', COALESCE((SELECT payments FROM _ts_quarterly_pmt x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
          'concentration', jsonb_build_object(
            'topNames', COALESCE((SELECT to_jsonb(top_names) FROM _ts_quarterly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb),
            'series',   COALESCE((SELECT series             FROM _ts_quarterly_conc x WHERE x.ccy = ct.ccy AND x.period_key = ct.period_key), '[]'::jsonb)
          )
        )
      )
    ) AS block
  FROM _ccy_totals ct;

  SELECT COALESCE(jsonb_object_agg(period_key, period_block), '{}'::jsonb)
  INTO v_per_period
  FROM (SELECT period_key, jsonb_build_object('perCurrency', jsonb_object_agg(ccy, block)) AS period_block
        FROM _per_period_ccy GROUP BY period_key) z;

  v_per_period := v_per_period
    || jsonb_build_object('all', COALESCE(v_per_period -> 'all', jsonb_build_object('perCurrency', '{}'::jsonb)))
    || jsonb_build_object('12m', COALESCE(v_per_period -> '12m', jsonb_build_object('perCurrency', '{}'::jsonb)))
    || jsonb_build_object('6m',  COALESCE(v_per_period -> '6m',  jsonb_build_object('perCurrency', '{}'::jsonb)))
    || jsonb_build_object('3m',  COALESCE(v_per_period -> '3m',  jsonb_build_object('perCurrency', '{}'::jsonb)))
    || jsonb_build_object('1m',  COALESCE(v_per_period -> '1m',  jsonb_build_object('perCurrency', '{}'::jsonb)));

  -- ==========================================================================
  -- Fair Payment Code scorecard
  -- Days-to-pay distribution over invoices PAID in the last 6 months, split
  -- all vs "small supplier" (bottom 50% of active suppliers by 6-month spend,
  -- a headcount proxy). amt_days = SUM(amount * days-to-pay) so the app can
  -- cost pulling a bucket under a threshold. Measured invoice date -> paid date.
  -- ==========================================================================
  WITH recent AS (
    SELECT upper(currency) AS ccy, supplier_identifier, amount,
           (paid_date - invoice_date) AS dtp
    FROM buyer_invoices
    WHERE upload_id = p_upload_id AND excluded IS NOT TRUE
      AND currency IS NOT NULL AND invoice_date IS NOT NULL AND paid_date IS NOT NULL
      AND paid_date >= (v_max_date - interval '6 months')
  ),
  sup6 AS (
    SELECT ccy, supplier_identifier, sum(amount) AS spend6
    FROM recent GROUP BY ccy, supplier_identifier
  ),
  small AS (
    SELECT ccy, supplier_identifier,
           (ntile(2) OVER (PARTITION BY ccy ORDER BY spend6) = 1) AS is_small
    FROM sup6
  ),
  classified AS (
    SELECT r.ccy,
      CASE WHEN r.dtp <= 30 THEN 'd30' WHEN r.dtp <= 60 THEN 'd60' ELSE 'd61' END AS bkt,
      s.is_small, r.amount AS amt, (r.amount * r.dtp) AS amt_days
    FROM recent r JOIN small s USING (ccy, supplier_identifier)
  ),
  agg AS (
    SELECT ccy, 'all'   AS scope, bkt, count(*)::int AS n, sum(amt)::numeric AS amt, sum(amt_days)::numeric AS amt_days
    FROM classified GROUP BY ccy, bkt
    UNION ALL
    SELECT ccy, 'small' AS scope, bkt, count(*)::int,       sum(amt)::numeric,       sum(amt_days)::numeric
    FROM classified WHERE is_small GROUP BY ccy, bkt
  ),
  by_scope AS (
    SELECT ccy, scope,
      jsonb_object_agg(bkt, jsonb_build_object('n', n, 'amt', round(amt, 2), 'amtDays', round(amt_days, 2))) AS buckets
    FROM agg GROUP BY ccy, scope
  )
  SELECT jsonb_object_agg(ccy, scopes || jsonb_build_object('windowDays', GREATEST(LEAST(183, v_max_date - v_min_date), 1)))
  INTO v_fair
  FROM (SELECT ccy, jsonb_object_agg(scope, buckets) AS scopes FROM by_scope GROUP BY ccy) z;

  v_stats := jsonb_build_object(
    'uploadMeta',  v_upload_meta,
    'overall',     v_overall,
    'perPeriod',   v_per_period,
    'fairPayment', COALESCE(v_fair, '{}'::jsonb),
    'warnings',    v_warnings
  );

  INSERT INTO buyer_upload_snapshots (
    upload_id, buyer_id, schema_version, stats, computed_at,
    invoice_count, cn_count, computed_in_ms
  ) VALUES (
    p_upload_id, v_buyer_id, 22, v_stats, now(),
    v_invoice_count, v_cn_count,
    extract(milliseconds FROM (clock_timestamp() - v_started_at))::integer
  )
  ON CONFLICT (upload_id) DO UPDATE SET
    buyer_id       = EXCLUDED.buyer_id,
    schema_version = EXCLUDED.schema_version,
    stats          = EXCLUDED.stats,
    computed_at    = EXCLUDED.computed_at,
    invoice_count  = EXCLUDED.invoice_count,
    cn_count       = EXCLUDED.cn_count,
    computed_in_ms = EXCLUDED.computed_in_ms;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
declare
  claims jsonb;
  v_role text;
  v_supplier text;
  v_buyer text;
  v_branch text;
begin
  select role, supplier_id, buyer_id, branch_id
    into v_role, v_supplier, v_buyer, v_branch
  from public.user_profiles
  where id = (event->>'user_id')::uuid;

  claims := coalesce(event->'claims', '{}'::jsonb);

  -- ensure app_metadata exists so jsonb_set can write nested keys
  if not (claims ? 'app_metadata') then
    claims := jsonb_set(claims, '{app_metadata}', '{}'::jsonb);
  end if;

  claims := jsonb_set(claims, '{app_metadata,user_role}',   coalesce(to_jsonb(v_role),     'null'::jsonb));
  claims := jsonb_set(claims, '{app_metadata,supplier_id}', coalesce(to_jsonb(v_supplier), 'null'::jsonb));
  claims := jsonb_set(claims, '{app_metadata,buyer_id}',    coalesce(to_jsonb(v_buyer),    'null'::jsonb));
  claims := jsonb_set(claims, '{app_metadata,branch_id}',   coalesce(to_jsonb(v_branch),   'null'::jsonb));

  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.default_created_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if new.created_at is null then
    new.created_at := now();
  end if;
  return new;
end; $function$
;

CREATE OR REPLACE FUNCTION public.factorflow_apply_time_transitions()
 RETURNS TABLE(invoices_scanned integer, invoices_updated integer, rows_skipped_null integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_scanned  integer := 0;
  v_updated  integer := 0;
  v_skipped  integer := 0;
BEGIN
  -- Count what we're about to look at (for return value / logging).
  SELECT COUNT(*) INTO v_scanned
  FROM invoices
  WHERE funding_status IN ('funded', 'at_risk', 'overdue', 'recovery_mode');

  SELECT COUNT(*) INTO v_skipped
  FROM invoices
  WHERE funding_status IN ('funded', 'at_risk', 'overdue', 'recovery_mode')
    AND debt_balance IS NULL;

  -- Single set-based UPDATE. The CASE cascade mirrors processForDate's
  -- arm order exactly. Reading top-to-bottom:
  --   1. fully_repaid (write-off branch + general)
  --   2. recovery_mode (settled/cancelled with balance, declined, dilution below cap+int)
  --   3. at_risk (dilution below amount — non-time-based)
  --   4. time-based arm (recovery/at_risk/overdue thresholds, defaulting to funded)
  WITH derived AS (
    SELECT
      i.id,
      i.funding_status AS current_funding_status,
      i.debt_balance,
      i.balance_owed,
      i.current_invoice_status,
      i.disputed_date,
      i.amount,
      i.partial_approved_amount,
      i.capital_due,
      i.interest_charged,
      i.amount_post_dilutions,
      i.funded_date,
      i.due_date,
      -- Per-program thresholds (with defaults matching the JS).
      COALESCE(fp.threshold_overdue, 1)            AS th_overdue,
      COALESCE(fp.threshold_at_risk, 7)            AS th_at_risk,
      COALESCE(fp.threshold_recovery, 30)          AS th_recovery,
      COALESCE(fp.threshold_dispute_at_risk, 1)    AS th_dispute_at_risk,
      COALESCE(fp.threshold_dispute_recovery, 14)  AS th_dispute_recovery,
      -- Effective amount: min(amount, partial_approved_amount if >0, amount_post_dilutions).
      -- Mirrors the JS:
      --   effectiveAmt = amount
      --   if partial_approved_amount > 0 AND partial_approved_amount < effective: effective = partial_approved_amount
      --   if amount_post_dilutions < effective: effective = amount_post_dilutions
      LEAST(
        i.amount,
        CASE WHEN COALESCE(i.partial_approved_amount, 0) > 0
             THEN i.partial_approved_amount
             ELSE i.amount
        END,
        COALESCE(i.amount_post_dilutions, i.amount)
      ) AS effective_amt,
      -- Days overdue: if past due, days from due_date to today; else 0.
      -- due_date is stored as text in this schema (JS-side YYYY-MM-DD strings),
      -- so we cast to date for arithmetic. funded_date is only used in NULL
      -- checks below, so no cast is needed for it.
      CASE
        WHEN i.due_date IS NOT NULL AND i.due_date::date < CURRENT_DATE
          THEN (CURRENT_DATE - i.due_date::date)
        ELSE 0
      END AS days_overdue,
      -- Days disputed: only if currently disputed AND we have a disputed_date.
      -- disputed_date IS a proper date column (added by today's migration).
      CASE
        WHEN i.current_invoice_status = 'Disputed' AND i.disputed_date IS NOT NULL
          THEN (CURRENT_DATE - i.disputed_date)
        ELSE 0
      END AS days_disputed,
      (i.due_date IS NOT NULL AND i.due_date::date < CURRENT_DATE) AS past_due,
      (i.current_invoice_status IN ('Settled', 'Cancelled', 'Declined')) AS terminal_inv_status
    FROM invoices i
    LEFT JOIN funding_programs fp ON fp.id = i.funding_program
    WHERE i.funding_status IN ('funded', 'at_risk', 'overdue', 'recovery_mode')
      AND i.debt_balance IS NOT NULL  -- skip un-derived rows
  ),
  computed AS (
    SELECT
      d.id,
      d.current_funding_status,
      CASE
        -- Arm 6 (JS line 1955): general fully_repaid.
        -- Excludes the special case capital_due=0 AND funded_date IS NOT NULL
        -- (a zero-capital invoice that's been "funded" is purchased, not repaid).
        WHEN d.debt_balance < 0.005
             AND NOT (d.capital_due = 0 AND d.funded_date IS NOT NULL)
          THEN 'fully_repaid'
        -- Arm 7 (JS line 1956): settled/cancelled with balance still owing.
        WHEN d.current_invoice_status IN ('Settled', 'Cancelled')
             AND d.debt_balance > 0.01
          THEN 'recovery_mode'
        -- Arm 8 (JS line 1957): declined.
        WHEN d.current_invoice_status = 'Declined'
          THEN 'recovery_mode'
        -- Arm 9 (JS line 1958): funded invoice with effective amount below cap+int.
        WHEN d.funded_date IS NOT NULL
             AND d.effective_amt < (d.capital_due + d.interest_charged) - 0.01
          THEN 'recovery_mode'
        -- Arm 10 (JS line 1959): funded invoice with effective amount below face.
        WHEN d.funded_date IS NOT NULL
             AND d.effective_amt < d.amount - 0.01
          THEN 'at_risk'
        -- Time-based arm (JS lines 1968–1971), evaluated against per-program thresholds.
        WHEN d.current_invoice_status IN ('Buyer Default', 'Declined')
             OR d.days_overdue > d.th_recovery
             OR d.days_disputed > d.th_dispute_recovery
          THEN 'recovery_mode'
        WHEN d.days_overdue > d.th_at_risk
             OR (d.current_invoice_status = 'Disputed' AND d.days_disputed > d.th_dispute_at_risk)
          THEN 'at_risk'
        WHEN d.past_due AND d.days_overdue >= d.th_overdue
          THEN 'overdue'
        ELSE 'funded'
      END AS new_funding_status
    FROM derived d
  )
  UPDATE invoices
     SET funding_status = c.new_funding_status
    FROM computed c
   WHERE invoices.id = c.id
     AND c.new_funding_status IS DISTINCT FROM c.current_funding_status;

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  -- Audit row so we can see runs in the audit log.
  -- Column shape mirrors the JS-side insert at Dashboard.jsx ~line 1753.
  -- Best-effort: if audit_log shape doesn't match, swallow and continue.
  BEGIN
    INSERT INTO audit_log (timestamp, display_time, action, details, context)
    VALUES (
      NOW(),
      to_char(NOW() AT TIME ZONE 'UTC', 'DD Mon YYYY, HH24:MI:SS') || ' UTC',
      'Cron: Time Transitions',
      format('Scanned %s; updated %s; skipped %s (null debt_balance)',
             v_scanned, v_updated, v_skipped),
      jsonb_build_object(
        'scanned', v_scanned,
        'updated', v_updated,
        'skipped_null', v_skipped,
        'run_at', NOW()
      )
    );
  EXCEPTION WHEN OTHERS THEN
    -- Swallow audit errors — don't fail the whole job because logging broke.
    NULL;
  END;

  RETURN QUERY SELECT v_scanned, v_updated, v_skipped;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.factorflow_backfill_snapshots(p_supplier_entity_id text, p_from date DEFAULT NULL::date, p_to date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date)
 RETURNS TABLE(invoices_processed integer, rows_written integer, range_from date, range_to date)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_from date;
  v_rows integer := 0;
  v_inv  integer := 0;
BEGIN
  SELECT COALESCE(p_from, min(invoice_date)) INTO v_from
  FROM invoices
  WHERE supplier_entity_id = p_supplier_entity_id
    AND invoice_date IS NOT NULL;

  IF v_from IS NULL THEN
    RETURN QUERY SELECT 0, 0, p_from, p_to;
    RETURN;
  END IF;

  SELECT count(*) INTO v_inv
  FROM invoices
  WHERE supplier_entity_id = p_supplier_entity_id
    AND invoice_date IS NOT NULL
    AND current_invoice_status NOT IN ('Cancelled','Declined','Disputed','Buyer Default');

  WITH scope AS (
    SELECT i.*
    FROM invoices i
    WHERE i.supplier_entity_id = p_supplier_entity_id
      AND i.invoice_date IS NOT NULL
      AND i.current_invoice_status NOT IN ('Cancelled','Declined','Disputed','Buyer Default')
  ),
  days AS (
    SELECT s.*, gs::date AS d
    FROM scope s,
    LATERAL generate_series(
      GREATEST(s.invoice_date, v_from),
      LEAST(COALESCE(s.settled_date - 1, p_to), p_to),
      interval '1 day'
    ) AS gs
  ),
  ins AS (
    INSERT INTO daily_book_snapshots (
      snapshot_date, invoice_id,
      funding_program, supplier_id, supplier_entity_id, buyer_id, buyer_entity_id, currency,
      funding_status, invoice_status, current_invoice_status, invoice_status_history,
      approved_date, invoice_date, due_date, funded_date, fully_repaid_date, settled_date, disputed_date,
      amount, capital_due, interest_charged, partial_approved_amount, amount_post_dilutions,
      capital_outstanding, interest_outstanding, penalty_outstanding,
      holdback, holdback_outstanding, holdback_overdrawn, debt_balance, balance_owed,
      advance_rate, annual_rate, penalty_rate,
      pending_top_up_amount, pending_top_up_date, pending_top_up_rate,
      do_not_advance, do_not_purchase, pending_doctype_confirmation,
      voided, void_reason, voided_at,
      buyer_ref, supplier_ref, invoice_reference,
      days_overdue, is_backfilled
    )
    SELECT
      d.d, d.id,
      d.funding_program, d.supplier_id, d.supplier_entity_id, d.buyer_id, d.buyer_entity_id, d.currency,
      d.funding_status, d.invoice_status,
      CASE
        WHEN d.partial_approved_amount IS NOT NULL
             AND d.partial_approved_amount > 0
             AND d.partial_approved_amount < d.amount
          THEN 'Approved in Part'
        ELSE 'Approved in Full'
      END,
      d.invoice_status_history,
      d.approved_date, d.invoice_date, d.due_date, d.funded_date, d.fully_repaid_date, d.settled_date, d.disputed_date,
      d.amount, d.capital_due, d.interest_charged, d.partial_approved_amount, d.amount_post_dilutions,
      0, 0, 0,
      d.holdback, d.holdback_outstanding, d.holdback_overdrawn, d.debt_balance, d.balance_owed,
      d.advance_rate, d.annual_rate, d.penalty_rate,
      d.pending_top_up_amount, d.pending_top_up_date, d.pending_top_up_rate,
      d.do_not_advance, d.do_not_purchase, d.pending_doctype_confirmation,
      d.voided, d.void_reason, d.voided_at,
      d.buyer_ref, d.supplier_ref, d.invoice_reference,
      CASE WHEN d.due_date IS NOT NULL AND d.d > d.due_date THEN (d.d - d.due_date) ELSE 0 END,
      true
    FROM days d
    ON CONFLICT (invoice_id, snapshot_date) DO UPDATE SET
      funding_program              = EXCLUDED.funding_program,
      supplier_id                  = EXCLUDED.supplier_id,
      supplier_entity_id           = EXCLUDED.supplier_entity_id,
      buyer_id                     = EXCLUDED.buyer_id,
      buyer_entity_id              = EXCLUDED.buyer_entity_id,
      currency                     = EXCLUDED.currency,
      funding_status               = EXCLUDED.funding_status,
      invoice_status               = EXCLUDED.invoice_status,
      current_invoice_status       = EXCLUDED.current_invoice_status,
      invoice_status_history       = EXCLUDED.invoice_status_history,
      approved_date                = EXCLUDED.approved_date,
      invoice_date                 = EXCLUDED.invoice_date,
      due_date                     = EXCLUDED.due_date,
      funded_date                  = EXCLUDED.funded_date,
      fully_repaid_date            = EXCLUDED.fully_repaid_date,
      settled_date                 = EXCLUDED.settled_date,
      disputed_date                = EXCLUDED.disputed_date,
      amount                       = EXCLUDED.amount,
      capital_due                  = EXCLUDED.capital_due,
      interest_charged             = EXCLUDED.interest_charged,
      partial_approved_amount      = EXCLUDED.partial_approved_amount,
      amount_post_dilutions        = EXCLUDED.amount_post_dilutions,
      capital_outstanding          = EXCLUDED.capital_outstanding,
      interest_outstanding         = EXCLUDED.interest_outstanding,
      penalty_outstanding          = EXCLUDED.penalty_outstanding,
      holdback                     = EXCLUDED.holdback,
      holdback_outstanding         = EXCLUDED.holdback_outstanding,
      holdback_overdrawn           = EXCLUDED.holdback_overdrawn,
      debt_balance                 = EXCLUDED.debt_balance,
      balance_owed                 = EXCLUDED.balance_owed,
      advance_rate                 = EXCLUDED.advance_rate,
      annual_rate                  = EXCLUDED.annual_rate,
      penalty_rate                 = EXCLUDED.penalty_rate,
      pending_top_up_amount        = EXCLUDED.pending_top_up_amount,
      pending_top_up_date          = EXCLUDED.pending_top_up_date,
      pending_top_up_rate          = EXCLUDED.pending_top_up_rate,
      do_not_advance               = EXCLUDED.do_not_advance,
      do_not_purchase              = EXCLUDED.do_not_purchase,
      pending_doctype_confirmation = EXCLUDED.pending_doctype_confirmation,
      voided                       = EXCLUDED.voided,
      void_reason                  = EXCLUDED.void_reason,
      voided_at                    = EXCLUDED.voided_at,
      buyer_ref                    = EXCLUDED.buyer_ref,
      supplier_ref                 = EXCLUDED.supplier_ref,
      invoice_reference            = EXCLUDED.invoice_reference,
      days_overdue                 = EXCLUDED.days_overdue,
      is_backfilled                = true,
      written_at                   = NOW()
    WHERE daily_book_snapshots.is_backfilled IS DISTINCT FROM false
    RETURNING 1
  )
  SELECT count(*) INTO v_rows FROM ins;

  BEGIN
    INSERT INTO audit_log (created_at, event_type, details, context)
    VALUES (
      NOW(),
      'Backfill: Daily Snapshot',
      format('Backfill for supplier %s over %s..%s: %s invoices, %s rows written',
             p_supplier_entity_id, v_from, p_to, v_inv, v_rows),
      jsonb_build_object('supplier_entity_id', p_supplier_entity_id, 'range_from', v_from,
                         'range_to', p_to, 'invoices_processed', v_inv, 'rows_written', v_rows,
                         'run_at', NOW())
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN QUERY SELECT v_inv, v_rows, v_from, p_to;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.factorflow_compute_dynamic_limits(p_as_of date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_from date := p_as_of - 59;
  v_to   date := p_as_of;
  v_rows integer := 0;
BEGIN
  DELETE FROM supplier_program_buyer_limit;

  WITH sb AS (
    -- Credit basis: program-agnostic avg daily outstanding per supplier-buyer-ccy.
    SELECT
      s.supplier_entity_id,
      s.buyer_entity_id,
      s.currency,
      SUM(
        CASE WHEN s.current_invoice_status = 'Approved in Part'
             THEN COALESCE(s.partial_approved_amount, 0)
             ELSE COALESCE(s.amount, 0)
        END
      )                                AS dollar_days,
      count(DISTINCT s.snapshot_date)  AS sample_days
    FROM daily_book_snapshots s
    JOIN supplier_backfill b
      ON b.supplier_entity_id = s.supplier_entity_id
     AND b.status = 'ready'
    WHERE s.snapshot_date BETWEEN v_from AND v_to
      AND s.current_invoice_status IN ('Received','Approved in Full','Approved in Part')
      AND s.days_overdue = 0
      AND s.buyer_entity_id IS NOT NULL
      AND s.supplier_entity_id IS NOT NULL
    GROUP BY s.supplier_entity_id, s.buyer_entity_id, s.currency
  ),
  isz AS (
    -- Invoice-size basis: avg face amount over invoices issued in the window,
    -- excluding terminal-bad statuses. Sourced from canonical invoices (a per-
    -- invoice flow average, not a daily-snapshot stock average). Ready-gated.
    SELECT
      i.supplier_entity_id,
      i.buyer_entity_id,
      i.currency,
      AVG(COALESCE(i.amount, 0)) AS avg_invoice_size,
      count(*)                   AS invoice_count
    FROM invoices i
    JOIN supplier_backfill b
      ON b.supplier_entity_id = i.supplier_entity_id
     AND b.status = 'ready'
    WHERE i.invoice_date BETWEEN v_from AND v_to
      AND COALESCE(i.current_invoice_status, '') NOT IN ('Cancelled','Declined','Disputed','Buyer Default')
      AND i.buyer_entity_id IS NOT NULL
      AND i.supplier_entity_id IS NOT NULL
    GROUP BY i.supplier_entity_id, i.buyer_entity_id, i.currency
  ),
  prog AS (
    -- Dynamic-enabled programs (credit OR invoice) expanded over eligible buyers,
    -- carrying both metric toggles, per-buyer multiples and optional ceilings.
    SELECT
      p.id        AS funding_program,
      p.currency  AS currency,
      eb.value    AS buyer_entity_id,
      ((p.dynamic_limit->>'enabled')::boolean IS TRUE)                        AS credit_on,
      COALESCE( (p.dynamic_limit->'perBuyer'->> eb.value)::numeric,
                (p.dynamic_limit->>'defaultMultiple')::numeric, 0 )           AS multiple,
      (p.dynamic_limit->>'ceiling')::numeric                                  AS ceiling,
      ((p.dynamic_limit->>'invoiceEnabled')::boolean IS TRUE)                 AS invoice_on,
      COALESCE( (p.dynamic_limit->'invoicePerBuyer'->> eb.value)::numeric,
                (p.dynamic_limit->>'invoiceDefaultMultiple')::numeric, 0 )    AS invoice_multiple,
      (p.dynamic_limit->>'invoiceCeiling')::numeric                          AS invoice_ceiling
    FROM funding_programs p
    CROSS JOIN LATERAL jsonb_array_elements_text(COALESCE(p.eligible_buyers, '[]'::jsonb)) AS eb(value)
    WHERE (p.dynamic_limit->>'enabled')::boolean IS TRUE
       OR (p.dynamic_limit->>'invoiceEnabled')::boolean IS TRUE
  ),
  keys AS (
    SELECT supplier_entity_id, buyer_entity_id, currency FROM sb
    UNION
    SELECT supplier_entity_id, buyer_entity_id, currency FROM isz
  ),
  calc AS (
    SELECT
      prog.funding_program,
      k.supplier_entity_id,
      k.buyer_entity_id,
      prog.currency,
      -- credit metric (null when credit toggle off or no basis)
      CASE WHEN prog.credit_on THEN (sb.dollar_days / 60.0) END AS avg_outstanding,
      sb.sample_days,
      CASE WHEN prog.credit_on THEN prog.multiple END           AS multiple,
      CASE WHEN prog.credit_on THEN prog.ceiling END            AS ceiling,
      -- invoice metric (null when invoice toggle off or no basis)
      CASE WHEN prog.invoice_on THEN isz.avg_invoice_size END   AS avg_invoice_size,
      isz.invoice_count,
      CASE WHEN prog.invoice_on THEN prog.invoice_multiple END  AS invoice_multiple,
      CASE WHEN prog.invoice_on THEN prog.invoice_ceiling END   AS invoice_ceiling
    FROM keys k
    JOIN prog
      ON prog.buyer_entity_id = k.buyer_entity_id
     AND prog.currency        = k.currency
    LEFT JOIN sb
      ON sb.supplier_entity_id = k.supplier_entity_id
     AND sb.buyer_entity_id    = k.buyer_entity_id
     AND sb.currency           = k.currency
    LEFT JOIN isz
      ON isz.supplier_entity_id = k.supplier_entity_id
     AND isz.buyer_entity_id    = k.buyer_entity_id
     AND isz.currency           = k.currency
    -- keep only rows that produce at least one usable metric
    WHERE (prog.credit_on  AND sb.dollar_days     IS NOT NULL)
       OR (prog.invoice_on AND isz.avg_invoice_size IS NOT NULL)
  ),
  ins AS (
    INSERT INTO supplier_program_buyer_limit (
      funding_program, supplier_entity_id, buyer_entity_id, currency,
      avg_outstanding_60d, sample_days, multiple, computed_limit, ceiling, limit_value,
      avg_invoice_size_60d, invoice_sample_count, invoice_multiple, computed_invoice_limit, invoice_ceiling, invoice_limit_value,
      window_from, window_to, computed_at
    )
    SELECT
      funding_program, supplier_entity_id, buyer_entity_id, currency,
      round(avg_outstanding, 2),
      sample_days,
      multiple,
      round(avg_outstanding * multiple, 2),
      ceiling,
      CASE WHEN ceiling IS NOT NULL
           THEN LEAST(round(avg_outstanding * multiple, 2), ceiling)
           ELSE round(avg_outstanding * multiple, 2)
      END,
      round(avg_invoice_size, 2),
      invoice_count,
      invoice_multiple,
      round(avg_invoice_size * invoice_multiple, 2),
      invoice_ceiling,
      CASE WHEN invoice_ceiling IS NOT NULL
           THEN LEAST(round(avg_invoice_size * invoice_multiple, 2), invoice_ceiling)
           ELSE round(avg_invoice_size * invoice_multiple, 2)
      END,
      v_from, v_to, now()
    FROM calc
    RETURNING 1
  )
  SELECT count(*) INTO v_rows FROM ins;

  BEGIN
    INSERT INTO audit_log (created_at, event_type, details, context)
    VALUES (
      now(),
      'Cron: Dynamic Limits',
      format('Computed %s limit rows as of %s (window %s..%s)', v_rows, p_as_of, v_from, v_to),
      jsonb_build_object('as_of', p_as_of, 'window_from', v_from, 'window_to', v_to,
                         'rows', v_rows, 'run_at', now())
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN v_rows;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.factorflow_mark_backfill_ready(p_supplier_entity_id text, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date)
 RETURNS void
 LANGUAGE sql
AS $function$
  INSERT INTO supplier_backfill (supplier_entity_id, status, range_from, range_to, ready_at, updated_at)
  VALUES (p_supplier_entity_id, 'ready', p_from, p_to, now(), now())
  ON CONFLICT (supplier_entity_id) DO UPDATE SET
    status     = 'ready',
    range_from = COALESCE(EXCLUDED.range_from, supplier_backfill.range_from),
    range_to   = COALESCE(EXCLUDED.range_to,   supplier_backfill.range_to),
    ready_at   = now(),
    updated_at = now();
$function$
;

CREATE OR REPLACE FUNCTION public.factorflow_write_daily_snapshot(target_date date DEFAULT ((now() AT TIME ZONE 'UTC'::text))::date)
 RETURNS TABLE(snapshot_date_written date, rows_written integer, rows_skipped_historic integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_written  integer := 0;
  v_skipped  integer := 0;
BEGIN
  SELECT COUNT(*) INTO v_skipped
  FROM invoices
  WHERE funding_status = 'historic';

  INSERT INTO daily_book_snapshots (
    snapshot_date, invoice_id,
    funding_program, supplier_id, supplier_entity_id, buyer_id, buyer_entity_id, currency,
    funding_status, invoice_status, current_invoice_status, invoice_status_history,
    approved_date, invoice_date, due_date, funded_date, fully_repaid_date, settled_date, disputed_date,
    amount, capital_due, interest_charged, partial_approved_amount, amount_post_dilutions,
    capital_outstanding, interest_outstanding, penalty_outstanding,
    holdback, holdback_outstanding, holdback_overdrawn, debt_balance, balance_owed,
    advance_rate, annual_rate, penalty_rate,
    pending_top_up_amount, pending_top_up_date, pending_top_up_rate,
    do_not_advance, do_not_purchase, pending_doctype_confirmation,
    voided, void_reason, voided_at,
    buyer_ref, supplier_ref, invoice_reference,
    days_overdue, is_backfilled
  )
  SELECT
    target_date,
    i.id,
    i.funding_program, i.supplier_id, i.supplier_entity_id, i.buyer_id, i.buyer_entity_id, i.currency,
    i.funding_status, i.invoice_status, i.current_invoice_status, i.invoice_status_history,
    i.approved_date, i.invoice_date, i.due_date, i.funded_date, i.fully_repaid_date, i.settled_date, i.disputed_date,
    i.amount, i.capital_due, i.interest_charged, i.partial_approved_amount, i.amount_post_dilutions,
    i.capital_outstanding, i.interest_outstanding, i.penalty_outstanding,
    i.holdback, i.holdback_outstanding, i.holdback_overdrawn, i.debt_balance, i.balance_owed,
    i.advance_rate, i.annual_rate, i.penalty_rate,
    i.pending_top_up_amount, i.pending_top_up_date, i.pending_top_up_rate,
    i.do_not_advance, i.do_not_purchase, i.pending_doctype_confirmation,
    i.voided, i.void_reason, i.voided_at,
    i.buyer_ref, i.supplier_ref, i.invoice_reference,
    CASE
      WHEN i.due_date IS NOT NULL AND i.due_date::date < target_date
        THEN (target_date - i.due_date::date)
      ELSE 0
    END,
    false
  FROM invoices i
  WHERE i.funding_status IS DISTINCT FROM 'historic'
  ON CONFLICT (invoice_id, snapshot_date) DO UPDATE SET
    funding_program              = EXCLUDED.funding_program,
    supplier_id                  = EXCLUDED.supplier_id,
    supplier_entity_id           = EXCLUDED.supplier_entity_id,
    buyer_id                     = EXCLUDED.buyer_id,
    buyer_entity_id              = EXCLUDED.buyer_entity_id,
    currency                     = EXCLUDED.currency,
    funding_status               = EXCLUDED.funding_status,
    invoice_status               = EXCLUDED.invoice_status,
    current_invoice_status       = EXCLUDED.current_invoice_status,
    invoice_status_history       = EXCLUDED.invoice_status_history,
    approved_date                = EXCLUDED.approved_date,
    invoice_date                 = EXCLUDED.invoice_date,
    due_date                     = EXCLUDED.due_date,
    funded_date                  = EXCLUDED.funded_date,
    fully_repaid_date            = EXCLUDED.fully_repaid_date,
    settled_date                 = EXCLUDED.settled_date,
    disputed_date                = EXCLUDED.disputed_date,
    amount                       = EXCLUDED.amount,
    capital_due                  = EXCLUDED.capital_due,
    interest_charged             = EXCLUDED.interest_charged,
    partial_approved_amount      = EXCLUDED.partial_approved_amount,
    amount_post_dilutions        = EXCLUDED.amount_post_dilutions,
    capital_outstanding          = EXCLUDED.capital_outstanding,
    interest_outstanding         = EXCLUDED.interest_outstanding,
    penalty_outstanding          = EXCLUDED.penalty_outstanding,
    holdback                     = EXCLUDED.holdback,
    holdback_outstanding         = EXCLUDED.holdback_outstanding,
    holdback_overdrawn           = EXCLUDED.holdback_overdrawn,
    debt_balance                 = EXCLUDED.debt_balance,
    balance_owed                 = EXCLUDED.balance_owed,
    advance_rate                 = EXCLUDED.advance_rate,
    annual_rate                  = EXCLUDED.annual_rate,
    penalty_rate                 = EXCLUDED.penalty_rate,
    pending_top_up_amount        = EXCLUDED.pending_top_up_amount,
    pending_top_up_date          = EXCLUDED.pending_top_up_date,
    pending_top_up_rate          = EXCLUDED.pending_top_up_rate,
    do_not_advance               = EXCLUDED.do_not_advance,
    do_not_purchase              = EXCLUDED.do_not_purchase,
    pending_doctype_confirmation = EXCLUDED.pending_doctype_confirmation,
    voided                       = EXCLUDED.voided,
    void_reason                  = EXCLUDED.void_reason,
    voided_at                    = EXCLUDED.voided_at,
    buyer_ref                    = EXCLUDED.buyer_ref,
    supplier_ref                 = EXCLUDED.supplier_ref,
    invoice_reference            = EXCLUDED.invoice_reference,
    days_overdue                 = EXCLUDED.days_overdue,
    is_backfilled                = false,
    written_at                   = NOW();

  GET DIAGNOSTICS v_written = ROW_COUNT;

  BEGIN
    INSERT INTO audit_log (created_at, event_type, details, context)
    VALUES (
      NOW(),
      'Cron: Daily Snapshot',
      format('Snapshot for %s: %s rows written; %s historic invoices skipped',
             target_date, v_written, v_skipped),
      jsonb_build_object('snapshot_date', target_date, 'rows_written', v_written,
                         'skipped_historic', v_skipped, 'run_at', NOW())
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  RETURN QUERY SELECT target_date, v_written, v_skipped;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fill_holdback_alloc_supplier()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if new.supplier_id is null or new.supplier_entity_id is null then
    select h.supplier_id, h.supplier_entity_id
      into new.supplier_id, new.supplier_entity_id
    from holdback_payments h where h.hb_payment_id = new.hb_payment_id;
  end if;
  return new;
end; $function$
;

CREATE OR REPLACE FUNCTION public.fill_holdback_supplier()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if new.supplier_id is null then
    select i.supplier_id into new.supplier_id
    from invoices i where i.id = new.source_invoice_id;
  end if;
  if new.supplier_entity_id is null then
    select coalesce(i.supplier_entity_id, i.supplier_id) into new.supplier_entity_id
    from invoices i where i.id = new.source_invoice_id;
  end if;
  return new;
end; $function$
;

CREATE OR REPLACE FUNCTION public.fill_payment_allocation_supplier()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if new.supplier_id is null then
    select i.supplier_id into new.supplier_id
    from invoices i where i.id = new.invoice_id;
  end if;
  if new.supplier_entity_id is null then
    select coalesce(i.supplier_entity_id, i.supplier_id) into new.supplier_entity_id
    from invoices i where i.id = new.invoice_id;
  end if;
  return new;
end; $function$
;

CREATE OR REPLACE FUNCTION public.get_user_branch()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'branch_id', 'null');
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_buyer()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'buyer_id', 'null');
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_entity()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select case
    when public.get_user_role() = 'supplier' and public.get_user_branch() is not null
      then public.get_user_supplier() || ':' || public.get_user_branch()
    when public.get_user_role() = 'supplier'
      then public.get_user_supplier()
    when public.get_user_role() = 'buyer' and public.get_user_branch() is not null
      then public.get_user_buyer() || ':' || public.get_user_branch()
    when public.get_user_role() = 'buyer'
      then public.get_user_buyer()
    else null
  end;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_role()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'user_role', 'null');
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_supplier()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  select nullif(auth.jwt() -> 'app_metadata' ->> 'supplier_id', 'null');
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.user_profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'read_only');
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'handle_new_user failed: %', SQLERRM;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  SELECT get_user_role() = 'admin'::text;
$function$
;

CREATE OR REPLACE FUNCTION public.is_internal_user()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  select get_user_role() = any (array['admin','operations','supervisor']);
$function$
;

CREATE OR REPLACE FUNCTION public.pelagic_broadcast_supplier_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  rec       record;
  body      jsonb;
  v_parent  text;
  v_entity  text;
  v_event   text := TG_ARGV[0];   -- e.g. 'payment_change'
begin
  rec := coalesce(new, old);
  v_parent := rec.supplier_id;                                    -- parent (the group)
  v_entity := coalesce(rec.supplier_entity_id, rec.supplier_id);  -- parent or a branch

  body := jsonb_build_object(
    'operation',  lower(tg_op),
    'record',     to_jsonb(coalesce(new, old)),
    'old_record', case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end
  );

  -- realtime.send(payload jsonb, event text, topic text, private boolean)
  begin
    if v_parent is not null then
      perform realtime.send(body, v_event, 'supplier:' || v_parent, true);
    end if;

    if v_entity is not null
       and v_entity is distinct from v_parent then
      perform realtime.send(body, v_event, 'supplier_entity:' || v_entity, true);
    end if;
  exception when others then
    -- Never let a broadcast problem roll back the underlying write.
    raise warning 'pelagic_broadcast_supplier_change failed: %', sqlerrm;
  end;

  return null;  -- AFTER trigger
end;
$function$
;

CREATE OR REPLACE FUNCTION public.populate_buyer_monthly_aggregate(p_upload_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_buyer_id text;
  v_ref_date date;   -- staleness reference = latest invoice date in the upload
  v_overdue_days int := 30;  -- days PAST DUE DATE before an accepted invoice is "stale"
  v_mature_days  int := 60;  -- days PAST DUE DATE before an invoice "should be resolved by now"
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_internal_user() THEN
    RAISE EXCEPTION 'Only internal users can populate aggregates';
  END IF;

  SELECT buyer_id INTO v_buyer_id FROM buyer_uploads WHERE id = p_upload_id;
  IF v_buyer_id IS NULL THEN
    RAISE EXCEPTION 'Upload % has null buyer_id or does not exist', p_upload_id;
  END IF;

  SELECT max(invoice_date) INTO v_ref_date
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND invoice_date IS NOT NULL;

  DELETE FROM buyer_supplier_monthly WHERE upload_id = p_upload_id;

  INSERT INTO buyer_supplier_monthly (
    upload_id, buyer_id, ccy, supplier_identifier, supplier_name, ym, yw, yq, yr,
    invoice_count, total_spend, max_amount,
    paid_count, unpaid_count,
    sum_dpd, dpd_sample_size, on_time_count, late_count, very_late_count,
    late_1_14_count, late_15_30_count, late_31_60_count, late_61_plus_count,
    sum_days_to_paid, sum_stated_term, stated_term_n,
    first_invoice_in_month, last_invoice_in_month,
    short_pay_count, short_pay_amount, settled_count,
    rejected_count, rejected_amount,
    stale_count, stale_amount,
    gl_codes, cost_centres,
    term_hist, no_due_count, no_due_spend,
    outstanding_dollar_days,
    cancelled_count, cancelled_amount,
    mature_invoice_count, mature_resolved_count
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), supplier_identifier, max(supplier_name),
    to_char(date_trunc('month', invoice_date), 'YYYY-MM'),
    (array_agg(to_char(invoice_date, 'IYYY-"W"IW') ORDER BY invoice_date))[1],
    extract(year FROM invoice_date)::int || '-Q' || extract(quarter FROM invoice_date)::int,
    extract(year FROM invoice_date)::int,
    count(*)::int,
    sum(amount)::numeric,
    max(amount)::numeric,
    count(*) FILTER (WHERE paid_date IS NOT NULL)::int,
    count(*) FILTER (WHERE paid_date IS NULL)::int,
    COALESCE(sum(paid_date - due_date) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL), 0)::numeric,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) <= 0)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) > 0)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) > 30)::int,
    -- Exact DPD bands (paid, dated invoices). on_time_count above = dpd<=0;
    -- these four + on_time_count sum to dpd_sample_size, so the
    -- lateness distribution reconciles to coverage. No 50/50 splitting.
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) BETWEEN 1 AND 14)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) BETWEEN 15 AND 30)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) BETWEEN 31 AND 60)::int,
    count(*) FILTER (WHERE paid_date IS NOT NULL AND due_date IS NOT NULL AND (paid_date - due_date) >= 61)::int,
    -- Tier-B working-capital sums (mirror sum_dpd): days-to-pay and stated terms.
    COALESCE(sum(paid_date - invoice_date) FILTER (WHERE paid_date IS NOT NULL), 0)::numeric,
    COALESCE(sum(due_date  - invoice_date) FILTER (WHERE due_date  IS NOT NULL), 0)::numeric,
    count(*) FILTER (WHERE due_date IS NOT NULL)::int,
    min(invoice_date),
    max(invoice_date),
    -- Short-pay: SETTLED ('paid') invoices that settled below face value.
    -- Gated on invoice_status='paid' so in-flight (approved/processing) and
    -- rejected invoices that carry a partial paid_amount are NOT counted as dilution.
    count(*) FILTER (WHERE invoice_status = 'paid' AND paid_amount IS NOT NULL AND paid_amount < amount)::int,
    COALESCE(sum(amount - paid_amount) FILTER (WHERE invoice_status = 'paid' AND paid_amount IS NOT NULL AND paid_amount < amount), 0)::numeric,
    count(*) FILTER (WHERE paid_amount IS NOT NULL)::int,
    -- Rejected: dilution component 3, and a buyer-behaviour signal in its own
    -- right (dispute / non-acceptance). Kept separate from short-pay so the
    -- two never merge into one indistinct number.
    count(*) FILTER (WHERE invoice_status = 'rejected')::int,
    COALESCE(sum(amount) FILTER (WHERE invoice_status = 'rejected'), 0)::numeric,
    -- Stale: a buyer-behaviour signal — invoices the buyer has ACCEPTED
    -- (approved/processing) but left unpaid past their due date. Measured as
    -- days OVERDUE (ref_date - due_date), so it adapts to payment terms:
    -- the due_date already encodes 30/60/90-day terms, so a 90-day invoice
    -- only goes stale once genuinely overdue, not merely old. Rows with no
    -- due_date are excluded (no terms to measure against — we don't guess).
    count(*) FILTER (
      WHERE invoice_status IN ('approved', 'processing')
        AND due_date IS NOT NULL
        AND v_ref_date IS NOT NULL
        AND (v_ref_date - due_date) > v_overdue_days
    )::int,
    COALESCE(sum(amount) FILTER (
      WHERE invoice_status IN ('approved', 'processing')
        AND due_date IS NOT NULL
        AND v_ref_date IS NOT NULL
        AND (v_ref_date - due_date) > v_overdue_days
    ), 0)::numeric,
    -- Concentration source: distinct GL codes / cost centres this month.
    -- Aggregated inline over the grouped rows (the GROUP BY already buckets
    -- by supplier + month + currency), so no correlated subquery needed.
    -- DISTINCT inside jsonb_agg dedupes; FILTER drops nulls.
    COALESCE(
      (SELECT jsonb_agg(DISTINCT g) FROM unnest(array_agg(gl_code) FILTER (WHERE gl_code IS NOT NULL)) AS g),
      '[]'::jsonb),
    COALESCE(
      (SELECT jsonb_agg(DISTINCT c) FROM unnest(array_agg(cost_centre) FILTER (WHERE cost_centre IS NOT NULL)) AS c),
      '[]'::jsonb),
    -- Payment-terms histogram (dated invoices only): stated term (due-invoice)
    -- -> {n, spend}. Built from one array of {t,a} objects so term and amount
    -- stay paired. Plus no-due-date count/spend so the coverage gap is carried
    -- through rather than silently dropped from the average.
    COALESCE((
      SELECT jsonb_object_agg(z.term::text, jsonb_build_object(
               'n', z.n, 'spend', round(z.sp, 2),
               'dpdN', z.dpd_n, 'dpdSum', round(z.dpd_sum, 2),
               'dpdWSum', round(z.dpd_wsum, 2), 'dpdWAmt', round(z.dpd_wamt, 2)))
      FROM (
        SELECT (e->>'t')::int AS term,
               count(*)                                                            AS n,
               sum((e->>'a')::numeric)                                             AS sp,
               count(*)                       FILTER (WHERE (e->>'d') IS NOT NULL) AS dpd_n,
               COALESCE(sum((e->>'d')::numeric) FILTER (WHERE (e->>'d') IS NOT NULL), 0)                     AS dpd_sum,
               COALESCE(sum((e->>'d')::numeric * (e->>'a')::numeric) FILTER (WHERE (e->>'d') IS NOT NULL), 0) AS dpd_wsum,
               COALESCE(sum((e->>'a')::numeric) FILTER (WHERE (e->>'d') IS NOT NULL), 0)                      AS dpd_wamt
        FROM unnest(array_agg(jsonb_build_object(
               't', (due_date - invoice_date),
               'a', amount,
               'd', CASE WHEN paid_date IS NOT NULL AND due_date IS NOT NULL THEN (paid_date - due_date) END))) AS e
        WHERE (e->>'t') IS NOT NULL
        GROUP BY (e->>'t')::int
      ) z
    ), '{}'::jsonb),
    count(*) FILTER (WHERE due_date IS NULL)::int,
    COALESCE(sum(amount) FILTER (WHERE due_date IS NULL), 0)::numeric,
    -- ========================================================================
    -- AP float source: pound-days outstanding, from KNOWN outcomes only.
    --
    -- The old expression dated every invoice with no paid_date to v_ref_date,
    -- so an unresolved invoice accrued from issue right through to the end of
    -- the file. At ~10% paid-date coverage that is ~90% of the file running to
    -- the horizon, which is what produced ~495 implied days outstanding. The
    -- sum was right; the substitution was not.
    --
    -- Four ways an invoice is treated, in order:
    --   1. paid          → the real answer, no assumption at all
    --   2. terminal+date → rejection / cancellation stopped it being a live
    --                      payable on that date
    --   3. terminal, no date → seven days. A flag with no date still tells us
    --                      the outcome is KNOWN; only its timing is assumed,
    --                      and seven days is short enough not to inflate the
    --                      float. Ingest already writes invoice_date + 7 into
    --                      status_change_date, so this catches older rows.
    --   4. unknown       → contributes NOTHING. Not a cap, not a guess — an
    --                      abstention. This is what makes the result a FLOOR:
    --                      every pound-day in it is evidenced, and the true
    --                      float is this or higher, never lower.
    --
    -- The divisor does not change — the snapshot still divides by the full
    -- span of the file. Unknowns leave the numerator while the denominator
    -- stays whole, which is exactly why the answer is a minimum rather than an
    -- average of the invoices we happen to be able to see. The app labels it
    -- "at least" between 30-70% coverage and withholds it below 30%.
    --
    -- Still additive across supplier-months, so it rolls up to a period total.
    -- ========================================================================
    COALESCE(sum(
      amount * GREATEST(0,
        CASE
          WHEN paid_date IS NOT NULL
            THEN paid_date - invoice_date
          WHEN invoice_status IN ('rejected', 'cancelled')
               AND status_change_date IS NOT NULL
               AND status_change_date::date >= invoice_date
            THEN status_change_date::date - invoice_date
          WHEN invoice_status IN ('rejected', 'cancelled')
            THEN 7
          ELSE 0
        END
      )
    ), 0)::numeric,
    -- Cancelled: dilution component 4. Supplier-side by rule — it reduces what
    -- the supplier realises, so it belongs in the combined total, but it is
    -- never the buyer's failing and the snapshot keeps it out of the adverse
    -- rate that severities and flags read.
    count(*) FILTER (WHERE invoice_status = 'cancelled')::int,
    COALESCE(sum(amount) FILTER (WHERE invoice_status = 'cancelled'), 0)::numeric,
    -- Coverage gate inputs. Mature = due more than 60 days before the file
    -- horizon: invoices that should be settled by now. Coverage measured over
    -- ALL invoices would penalise recent data, because a young invoice has no
    -- outcome yet for perfectly good reasons — that is the whole point of
    -- filtering to the mature set. Resolved = paid, or terminal; both are
    -- known. Note what is absent: no assumption whatsoever about mature
    -- invoices still open. They may be genuinely late or missing a paid date,
    -- and the data often cannot tell you which. The gate does not need to know
    -- — a small unknown share barely moves the floor, and a large one makes it
    -- untrustworthy either way.
    count(*) FILTER (
      WHERE due_date IS NOT NULL
        AND v_ref_date IS NOT NULL
        AND (v_ref_date - due_date) > v_mature_days
    )::int,
    count(*) FILTER (
      WHERE due_date IS NOT NULL
        AND v_ref_date IS NOT NULL
        AND (v_ref_date - due_date) > v_mature_days
        AND (paid_date IS NOT NULL OR invoice_status IN ('rejected', 'cancelled'))
    )::int
  FROM buyer_invoices bi
  WHERE upload_id = p_upload_id
    AND excluded IS NOT TRUE
    AND supplier_identifier IS NOT NULL
    AND currency IS NOT NULL
    AND invoice_date IS NOT NULL
  GROUP BY upper(currency), supplier_identifier,
           to_char(date_trunc('month', invoice_date), 'YYYY-MM'),
           extract(year FROM invoice_date)::int || '-Q' || extract(quarter FROM invoice_date)::int,
           extract(year FROM invoice_date)::int;

  -- CN merge (unchanged)
  INSERT INTO buyer_supplier_monthly (
    upload_id, buyer_id, ccy, supplier_identifier, supplier_name, ym, yw, yq, yr,
    cn_count, cn_total
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), supplier_identifier, max(supplier_name),
    to_char(date_trunc('month', cn_date), 'YYYY-MM'),
    (array_agg(to_char(cn_date, 'IYYY-"W"IW') ORDER BY cn_date))[1],
    extract(year FROM cn_date)::int || '-Q' || extract(quarter FROM cn_date)::int,
    extract(year FROM cn_date)::int,
    count(*)::int,
    sum(amount)::numeric
  FROM buyer_credit_notes
  WHERE upload_id = p_upload_id
    AND excluded IS NOT TRUE
    AND supplier_identifier IS NOT NULL
    AND currency IS NOT NULL
    AND cn_date IS NOT NULL
  GROUP BY upper(currency), supplier_identifier,
           to_char(date_trunc('month', cn_date), 'YYYY-MM'),
           extract(year FROM cn_date)::int || '-Q' || extract(quarter FROM cn_date)::int,
           extract(year FROM cn_date)::int
  ON CONFLICT (upload_id, ccy, supplier_identifier, ym) DO UPDATE
  SET cn_count = EXCLUDED.cn_count,
      cn_total = EXCLUDED.cn_total;

  -- Weekly aggregate (currency level) — unchanged
  DELETE FROM buyer_currency_weekly WHERE upload_id = p_upload_id;

  INSERT INTO buyer_currency_weekly (
    upload_id, buyer_id, ccy, yw, yr,
    invoice_count, total_spend, bucket_last_date,
    short_pay_count, short_pay_amount,
    rejected_count, rejected_amount,
    cancelled_count, cancelled_amount
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), to_char(invoice_date, 'IYYY-"W"IW'),
    extract(isoyear FROM invoice_date)::int,
    count(*)::int, sum(amount)::numeric, max(invoice_date),
    count(*) FILTER (WHERE invoice_status = 'paid' AND paid_amount IS NOT NULL AND paid_amount < amount)::int,
    COALESCE(sum(amount - paid_amount) FILTER (WHERE invoice_status = 'paid' AND paid_amount IS NOT NULL AND paid_amount < amount), 0)::numeric,
    -- Components 3 and 4 at weekly grain. Bucketed by invoice_date like the
    -- rest of this insert, which keeps each week's numerator and denominator
    -- describing the same invoices.
    count(*) FILTER (WHERE invoice_status = 'rejected')::int,
    COALESCE(sum(amount) FILTER (WHERE invoice_status = 'rejected'), 0)::numeric,
    count(*) FILTER (WHERE invoice_status = 'cancelled')::int,
    COALESCE(sum(amount) FILTER (WHERE invoice_status = 'cancelled'), 0)::numeric
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND currency IS NOT NULL AND invoice_date IS NOT NULL
  GROUP BY upper(currency), to_char(invoice_date, 'IYYY-"W"IW'), extract(isoyear FROM invoice_date)::int;

  INSERT INTO buyer_currency_weekly (
    upload_id, buyer_id, ccy, yw, yr, cn_count, cn_total, bucket_last_date
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), to_char(cn_date, 'IYYY-"W"IW'),
    extract(isoyear FROM cn_date)::int,
    count(*)::int, sum(amount)::numeric, max(cn_date)
  FROM buyer_credit_notes
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND currency IS NOT NULL AND cn_date IS NOT NULL
  GROUP BY upper(currency), to_char(cn_date, 'IYYY-"W"IW'), extract(isoyear FROM cn_date)::int
  ON CONFLICT (upload_id, ccy, yw) DO UPDATE
  SET cn_count = EXCLUDED.cn_count,
      cn_total = EXCLUDED.cn_total,
      bucket_last_date = GREATEST(buyer_currency_weekly.bucket_last_date, EXCLUDED.bucket_last_date);

  INSERT INTO buyer_currency_weekly (
    upload_id, buyer_id, ccy, yw, yr,
    paid_count_pw, sum_dpd_pw, on_time_count_pw, dpd_sample_pw, bucket_last_date,
    sum_days_to_paid_pw, sum_stated_term_pw
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), to_char(paid_date, 'IYYY-"W"IW'),
    extract(isoyear FROM paid_date)::int,
    count(*)::int, sum(paid_date - due_date)::numeric,
    count(*) FILTER (WHERE (paid_date - due_date) <= 0)::int,
    count(*)::int, max(paid_date),
    sum(paid_date - invoice_date)::numeric, sum(due_date - invoice_date)::numeric
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND currency IS NOT NULL
    AND paid_date IS NOT NULL AND due_date IS NOT NULL
  GROUP BY upper(currency), to_char(paid_date, 'IYYY-"W"IW'), extract(isoyear FROM paid_date)::int
  ON CONFLICT (upload_id, ccy, yw) DO UPDATE
  SET paid_count_pw    = EXCLUDED.paid_count_pw,
      sum_dpd_pw       = EXCLUDED.sum_dpd_pw,
      on_time_count_pw = EXCLUDED.on_time_count_pw,
      dpd_sample_pw    = EXCLUDED.dpd_sample_pw,
      bucket_last_date = GREATEST(buyer_currency_weekly.bucket_last_date, EXCLUDED.bucket_last_date),
      sum_days_to_paid_pw = EXCLUDED.sum_days_to_paid_pw,
      sum_stated_term_pw  = EXCLUDED.sum_stated_term_pw;

  -- per-currency paid-date period aggregate — unchanged
  DELETE FROM buyer_currency_paid_period WHERE upload_id = p_upload_id;

  INSERT INTO buyer_currency_paid_period (
    upload_id, buyer_id, ccy, period_kind, period_key,
    paid_count, sum_dpd, on_time_count, bucket_last_paid,
    sum_days_to_paid, sum_stated_term
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), 'M',
    to_char(date_trunc('month', paid_date), 'YYYY-MM'),
    count(*)::int,
    sum(paid_date - due_date)::numeric,
    count(*) FILTER (WHERE (paid_date - due_date) <= 0)::int,
    max(paid_date),
    sum(paid_date - invoice_date)::numeric,
    sum(due_date - invoice_date)::numeric
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND currency IS NOT NULL
    AND paid_date IS NOT NULL AND due_date IS NOT NULL
  GROUP BY upper(currency), to_char(date_trunc('month', paid_date), 'YYYY-MM');

  INSERT INTO buyer_currency_paid_period (
    upload_id, buyer_id, ccy, period_kind, period_key,
    paid_count, sum_dpd, on_time_count, bucket_last_paid,
    sum_days_to_paid, sum_stated_term
  )
  SELECT
    p_upload_id, v_buyer_id,
    upper(currency), 'Q',
    extract(year FROM paid_date)::int || '-Q' || extract(quarter FROM paid_date)::int,
    count(*)::int,
    sum(paid_date - due_date)::numeric,
    count(*) FILTER (WHERE (paid_date - due_date) <= 0)::int,
    max(paid_date),
    sum(paid_date - invoice_date)::numeric,
    sum(due_date - invoice_date)::numeric
  FROM buyer_invoices
  WHERE upload_id = p_upload_id AND excluded IS NOT TRUE AND currency IS NOT NULL
    AND paid_date IS NOT NULL AND due_date IS NOT NULL
  GROUP BY upper(currency), extract(year FROM paid_date)::int || '-Q' || extract(quarter FROM paid_date)::int;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.populate_prospect_suppliers(p_buyer_id text)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_permitted boolean;
  v_inserted  integer;
  v_updated   integer;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_internal_user() THEN
    RAISE EXCEPTION 'Only internal users can populate prospects';
  END IF;

  SELECT supplier_outreach_permitted INTO v_permitted
  FROM buyers WHERE id = p_buyer_id;

  IF v_permitted IS NOT TRUE THEN
    RAISE NOTICE 'Buyer % has supplier_outreach_permitted = false; skipping', p_buyer_id;
    RETURN 0;
  END IF;

  -- Per (supplier, ccy), grab the latest non-null name across months.
  WITH src AS (
    SELECT DISTINCT ON (supplier_identifier, ccy)
      supplier_identifier, ccy, supplier_name
    FROM buyer_supplier_monthly
    WHERE buyer_id = p_buyer_id
      AND invoice_count > 0
      AND supplier_identifier IS NOT NULL
    ORDER BY supplier_identifier, ccy, last_invoice_in_month DESC NULLS LAST
  ),
  upsert AS (
    INSERT INTO prospect_suppliers (
      buyer_id, supplier_identifier, supplier_name, currency, status,
      first_seen_at, last_seen_at
    )
    SELECT
      p_buyer_id, src.supplier_identifier, src.supplier_name, src.ccy,
      'lead', now(), now()
    FROM src
    ON CONFLICT (buyer_id, supplier_identifier, currency)
    DO UPDATE SET
      last_seen_at  = now(),
      supplier_name = COALESCE(EXCLUDED.supplier_name, prospect_suppliers.supplier_name)
    RETURNING (xmax = 0) AS was_insert
  )
  SELECT
    count(*) FILTER (WHERE was_insert)::int,
    count(*) FILTER (WHERE NOT was_insert)::int
  INTO v_inserted, v_updated
  FROM upsert;

  RAISE NOTICE 'Buyer %: inserted % new prospects, refreshed % existing',
    p_buyer_id, COALESCE(v_inserted, 0), COALESCE(v_updated, 0);

  RETURN COALESCE(v_inserted, 0);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.populate_prospect_suppliers_now(p_buyer_id text)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count integer;
BEGIN
  IF auth.uid() IS NOT NULL AND NOT is_internal_user() THEN
    RAISE EXCEPTION 'Only internal users can populate prospects';
  END IF;
  v_count := populate_prospect_suppliers(p_buyer_id);
  PERFORM refresh_buyer_upload_supplier_counts(p_buyer_id);
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.process_pending_snapshots()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
 SET statement_timeout TO '300s'
AS $function$
DECLARE
  v_upload_id uuid;
  v_buyer_id  text;
  v_started   timestamptz;
  v_perm_err  text;
BEGIN
  SELECT id INTO v_upload_id
  FROM buyer_uploads
  WHERE snapshot_status = 'pending'
  ORDER BY created_at ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  IF v_upload_id IS NULL THEN
    RETURN;
  END IF;

  v_started := clock_timestamp();

  UPDATE buyer_uploads
  SET snapshot_status     = 'computing',
      snapshot_started_at = v_started,
      snapshot_error      = NULL
  WHERE id = v_upload_id
  RETURNING buyer_id INTO v_buyer_id;

  BEGIN
    PERFORM populate_buyer_monthly_aggregate(v_upload_id);
    PERFORM compute_buyer_snapshot(v_upload_id);

    -- Step D: prospects (if buyer is permitted). Isolated exception
    -- handler — a failure here does NOT roll back the snapshot.
    BEGIN
      PERFORM populate_prospect_suppliers(v_buyer_id);
    EXCEPTION WHEN OTHERS THEN
      v_perm_err := SQLERRM;
      RAISE WARNING 'populate_prospect_suppliers failed for buyer %: %',
        v_buyer_id, v_perm_err;
    END;

    UPDATE buyer_uploads
    SET snapshot_status      = 'ready',
        snapshot_finished_at = clock_timestamp()
    WHERE id = v_upload_id;
  EXCEPTION WHEN OTHERS THEN
    UPDATE buyer_uploads
    SET snapshot_status      = 'failed',
        snapshot_finished_at = clock_timestamp(),
        snapshot_error       = SQLERRM
    WHERE id = v_upload_id;
  END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.prospect_suppliers_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.reclassify_buyer_doctype(p_buyer_id text, p_raw_document_type text, p_sign_bucket text, p_new_class text, p_new_subtype text DEFAULT NULL::text, p_scope_upload_id uuid DEFAULT NULL::uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_updated integer;
BEGIN
    IF NOT is_internal_user() THEN
        RAISE EXCEPTION 'Only internal users can reclassify document types';
    END IF;
    IF p_new_class NOT IN ('invoice','credit_note','disregard') THEN
        RAISE EXCEPTION 'Invalid class %', p_new_class;
    END IF;
    IF p_sign_bucket NOT IN ('positive','negative') THEN
        RAISE EXCEPTION 'Invalid sign bucket %', p_sign_bucket;
    END IF;

    -- Restate the stored rows. raw_document_type and sign_bucket are immutable
    -- provenance, so this always targets the right set even after the change.
    UPDATE buyer_documents
       SET doc_class   = p_new_class,
           doc_subtype = p_new_subtype
     WHERE buyer_id = p_buyer_id
       AND COALESCE(raw_document_type,'') = COALESCE(p_raw_document_type,'')
       AND sign_bucket = p_sign_bucket
       AND (p_scope_upload_id IS NULL OR upload_id = p_scope_upload_id);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    -- Update the standing per-buyer rule (unless this was a one-upload fix).
    IF p_scope_upload_id IS NULL THEN
        INSERT INTO buyer_doctype_aliases (buyer_id, raw_value, sign_bucket, canonical_value, doc_subtype)
        VALUES (p_buyer_id, COALESCE(p_raw_document_type,''), p_sign_bucket, p_new_class, p_new_subtype)
        ON CONFLICT (buyer_id, raw_value, sign_bucket)
        DO UPDATE SET canonical_value = EXCLUDED.canonical_value, doc_subtype = EXCLUDED.doc_subtype;
    END IF;

    -- Re-queue affected uploads so analytics recompute with the new split.
    UPDATE buyer_uploads SET snapshot_status = 'pending'
     WHERE buyer_id = p_buyer_id
       AND (p_scope_upload_id IS NULL OR id = p_scope_upload_id)
       AND id IN (
           SELECT DISTINCT upload_id FROM buyer_documents
            WHERE buyer_id = p_buyer_id
              AND COALESCE(raw_document_type,'') = COALESCE(p_raw_document_type,'')
              AND sign_bucket = p_sign_bucket
       );

    RETURN v_updated;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.refresh_buyer_upload_supplier_counts(p_buyer_id text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  delete from buyer_upload_supplier_counts where buyer_id = p_buyer_id;
  insert into buyer_upload_supplier_counts (buyer_id, upload_id, supplier_identifier, cnt)
  select buyer_id, upload_id, supplier_identifier, count(*)::bigint
  from buyer_invoices
  where buyer_id = p_buyer_id and excluded = false
  group by buyer_id, upload_id, supplier_identifier;
end; $function$
;

CREATE OR REPLACE FUNCTION public.supplier_rls_check()
 RETURNS jsonb
 LANGUAGE sql
AS $function$
  SELECT jsonb_build_object(
    'auth_uid', auth.uid(),
    'role', get_user_role(),
    'supplier_id', get_user_supplier(),
    'can_see_invoices_count', (SELECT count(*) FROM invoices),
    'can_see_payments_count', (SELECT count(*) FROM payments),
    'can_see_spq_count', (SELECT count(*) FROM supplier_payment_queue)
  );
$function$
;

CREATE OR REPLACE FUNCTION public.tasks_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE TRIGGER prospect_suppliers_updated_at BEFORE UPDATE ON public.prospect_suppliers FOR EACH ROW EXECUTE FUNCTION prospect_suppliers_set_updated_at();

CREATE TRIGGER trg_broadcast_hba_change AFTER INSERT OR DELETE OR UPDATE ON public.holdback_payment_allocations FOR EACH ROW EXECUTE FUNCTION pelagic_broadcast_supplier_change('holdback_change');

CREATE TRIGGER trg_broadcast_hbp_change AFTER INSERT OR DELETE OR UPDATE ON public.holdback_payments FOR EACH ROW EXECUTE FUNCTION pelagic_broadcast_supplier_change('holdback_change');

CREATE TRIGGER trg_broadcast_invoice_change AFTER INSERT OR DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION broadcast_invoice_change();

CREATE TRIGGER trg_broadcast_payalloc_change AFTER INSERT OR DELETE OR UPDATE ON public.payment_allocations FOR EACH ROW EXECUTE FUNCTION pelagic_broadcast_supplier_change('payment_change');

CREATE TRIGGER trg_broadcast_spq_change AFTER INSERT OR DELETE OR UPDATE ON public.supplier_payment_queue FOR EACH ROW EXECUTE FUNCTION pelagic_broadcast_supplier_change('spq_change');

CREATE TRIGGER trg_fill_hba_supplier BEFORE INSERT OR UPDATE ON public.holdback_payment_allocations FOR EACH ROW EXECUTE FUNCTION fill_holdback_alloc_supplier();

CREATE TRIGGER trg_fill_hbp_supplier BEFORE INSERT OR UPDATE ON public.holdback_payments FOR EACH ROW EXECUTE FUNCTION fill_holdback_supplier();

CREATE TRIGGER trg_fill_pa_supplier BEFORE INSERT OR UPDATE ON public.payment_allocations FOR EACH ROW EXECUTE FUNCTION fill_payment_allocation_supplier();

CREATE TRIGGER trg_spq_created_at BEFORE INSERT OR UPDATE ON public.supplier_payment_queue FOR EACH ROW EXECUTE FUNCTION default_created_at();

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.benchmarks ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_currency_paid_period ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_currency_weekly ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_doctype_aliases ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_status_aliases ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_supplier_monthly ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_upload_snapshots ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_upload_supplier_counts ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyer_uploads ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.buyers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.credit_notes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.csv_providers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.csv_review_queue ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.daily_book_snapshots ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.disregarded_documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entity_aliases ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.entity_notes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.funding_programs ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.holdback_payment_allocations ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.holdback_payments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.payment_allocations ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.prospect_groups ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.prospect_notes ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.prospect_suppliers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.provider_entity_aliases ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.rate_recompute_queue ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.supplier_backfill ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.supplier_payment_queue ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.supplier_program_buyer_limit ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.supplier_program_buyer_override ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can insert user profiles" ON public.user_profiles FOR INSERT TO authenticated WITH CHECK (is_admin());

CREATE POLICY "Admins can read all user profiles" ON public.user_profiles FOR SELECT TO authenticated USING (((id = auth.uid()) OR is_admin()));

CREATE POLICY "Admins can update user profiles" ON public.user_profiles FOR UPDATE TO public USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY audit_buyer_read ON public.audit_log FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id IS NOT NULL) AND (((get_user_branch() IS NULL) AND (buyer_id = get_user_buyer())) OR ((get_user_branch() IS NOT NULL) AND (buyer_entity_id = get_user_entity())))));

CREATE POLICY audit_internal_insert ON public.audit_log FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY audit_internal_read ON public.audit_log FOR SELECT TO public USING (is_internal_user());

CREATE POLICY audit_supplier_read ON public.audit_log FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (supplier_id IS NOT NULL) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY auth_admin_read_user_profiles ON public.user_profiles FOR SELECT TO supabase_auth_admin USING (true);

CREATE POLICY bcpp_buyer_select ON public.buyer_currency_paid_period FOR SELECT TO authenticated USING ((buyer_id = get_user_buyer()));

CREATE POLICY bcpp_internal_all ON public.buyer_currency_paid_period FOR ALL TO authenticated USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY bcw_buyer_read ON public.buyer_currency_weekly FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id = get_user_buyer())));

CREATE POLICY bcw_internal_delete ON public.buyer_currency_weekly FOR DELETE TO public USING (is_internal_user());

CREATE POLICY bcw_internal_insert ON public.buyer_currency_weekly FOR INSERT TO public WITH CHECK (is_internal_user());

CREATE POLICY bcw_internal_select ON public.buyer_currency_weekly FOR SELECT TO public USING (is_internal_user());

CREATE POLICY bcw_internal_update ON public.buyer_currency_weekly FOR UPDATE TO public USING (is_internal_user());

CREATE POLICY benchmarks_internal_all ON public.benchmarks FOR ALL TO authenticated USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY benchmarks_supplier_read ON public.benchmarks FOR SELECT TO public USING ((is_internal_user() OR (get_user_role() = ANY (ARRAY['supplier'::text, 'buyer'::text]))));

CREATE POLICY bi_snapshots_buyer_read ON public.buyer_upload_snapshots FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id = get_user_buyer())));

CREATE POLICY bi_snapshots_internal_delete ON public.buyer_upload_snapshots FOR DELETE TO public USING (is_admin());

CREATE POLICY bi_snapshots_internal_insert ON public.buyer_upload_snapshots FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY bi_snapshots_internal_read ON public.buyer_upload_snapshots FOR SELECT TO public USING (is_internal_user());

CREATE POLICY bi_snapshots_internal_update ON public.buyer_upload_snapshots FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY bsm_buyer_read ON public.buyer_supplier_monthly FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id = get_user_buyer())));

CREATE POLICY bsm_internal_delete ON public.buyer_supplier_monthly FOR DELETE TO public USING (is_internal_user());

CREATE POLICY bsm_internal_insert ON public.buyer_supplier_monthly FOR INSERT TO public WITH CHECK (is_internal_user());

CREATE POLICY bsm_internal_select ON public.buyer_supplier_monthly FOR SELECT TO public USING (is_internal_user());

CREATE POLICY bsm_internal_update ON public.buyer_supplier_monthly FOR UPDATE TO public USING (is_internal_user());

CREATE POLICY buusc_internal_read ON public.buyer_upload_supplier_counts FOR SELECT TO authenticated USING (is_internal_user());

CREATE POLICY buyer_doctype_aliases_internal_read ON public.buyer_doctype_aliases FOR SELECT TO public USING (is_internal_user());

CREATE POLICY buyer_doctype_aliases_internal_write ON public.buyer_doctype_aliases FOR ALL TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text]))) WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyer_documents_buyer_read ON public.buyer_documents FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id = get_user_buyer())));

CREATE POLICY buyer_documents_internal_delete ON public.buyer_documents FOR DELETE TO public USING (is_admin());

CREATE POLICY buyer_documents_internal_insert ON public.buyer_documents FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyer_documents_internal_read ON public.buyer_documents FOR SELECT TO public USING (is_internal_user());

CREATE POLICY buyer_documents_internal_update ON public.buyer_documents FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyer_status_aliases_read ON public.buyer_status_aliases FOR SELECT TO public USING (is_internal_user());

CREATE POLICY buyer_status_aliases_write ON public.buyer_status_aliases FOR ALL TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text]))) WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyer_uploads_buyer_read ON public.buyer_uploads FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (buyer_id = get_user_buyer())));

CREATE POLICY buyer_uploads_internal_delete ON public.buyer_uploads FOR DELETE TO public USING (is_admin());

CREATE POLICY buyer_uploads_internal_insert ON public.buyer_uploads FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyer_uploads_internal_read ON public.buyer_uploads FOR SELECT TO public USING (is_internal_user());

CREATE POLICY buyer_uploads_internal_update ON public.buyer_uploads FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyers_buyer_read ON public.buyers FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (id = get_user_buyer())));

CREATE POLICY buyers_internal_delete ON public.buyers FOR DELETE TO public USING (is_admin());

CREATE POLICY buyers_internal_insert ON public.buyers FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyers_internal_read ON public.buyers FOR SELECT TO public USING (is_internal_user());

CREATE POLICY buyers_internal_update ON public.buyers FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY buyers_supplier_read ON public.buyers FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (id IN ( SELECT DISTINCT i.buyer_id
   FROM invoices i
  WHERE (i.supplier_id = get_user_supplier())))));

CREATE POLICY cn_buyer_read ON public.credit_notes FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (((get_user_branch() IS NULL) AND (buyer_id = get_user_buyer())) OR ((get_user_branch() IS NOT NULL) AND (buyer_entity_id = get_user_entity())))));

CREATE POLICY cn_internal_delete ON public.credit_notes FOR DELETE TO public USING (is_admin());

CREATE POLICY cn_internal_insert ON public.credit_notes FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY cn_internal_read ON public.credit_notes FOR SELECT TO public USING (is_internal_user());

CREATE POLICY cn_internal_update ON public.credit_notes FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY cn_supplier_read ON public.credit_notes FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY csv_providers_internal_delete ON public.csv_providers FOR DELETE TO public USING (is_admin());

CREATE POLICY csv_providers_internal_insert ON public.csv_providers FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY csv_providers_internal_read ON public.csv_providers FOR SELECT TO public USING (is_internal_user());

CREATE POLICY csv_providers_internal_update ON public.csv_providers FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY csv_review_queue_internal_delete ON public.csv_review_queue FOR DELETE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY csv_review_queue_internal_insert ON public.csv_review_queue FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY csv_review_queue_internal_read ON public.csv_review_queue FOR SELECT TO public USING (is_internal_user());

CREATE POLICY csv_review_queue_internal_update ON public.csv_review_queue FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY daily_book_snapshots_internal_delete ON public.daily_book_snapshots FOR DELETE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY daily_book_snapshots_internal_insert ON public.daily_book_snapshots FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY daily_book_snapshots_internal_read ON public.daily_book_snapshots FOR SELECT TO public USING (is_internal_user());

CREATE POLICY daily_book_snapshots_internal_update ON public.daily_book_snapshots FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY disregarded_documents_internal_delete ON public.disregarded_documents FOR DELETE TO public USING (is_admin());

CREATE POLICY disregarded_documents_internal_insert ON public.disregarded_documents FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY disregarded_documents_internal_read ON public.disregarded_documents FOR SELECT TO public USING (is_internal_user());

CREATE POLICY disregarded_documents_internal_update ON public.disregarded_documents FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_aliases_internal_delete ON public.entity_aliases FOR DELETE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_aliases_internal_insert ON public.entity_aliases FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_aliases_internal_read ON public.entity_aliases FOR SELECT TO public USING (is_internal_user());

CREATE POLICY entity_aliases_internal_update ON public.entity_aliases FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_notes_internal_delete ON public.entity_notes FOR DELETE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_notes_internal_insert ON public.entity_notes FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY entity_notes_internal_read ON public.entity_notes FOR SELECT TO public USING (is_internal_user());

CREATE POLICY entity_notes_internal_update ON public.entity_notes FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY fp_internal_delete ON public.funding_programs FOR DELETE TO public USING (is_admin());

CREATE POLICY fp_internal_insert ON public.funding_programs FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY fp_internal_read ON public.funding_programs FOR SELECT TO public USING (is_internal_user());

CREATE POLICY fp_internal_update ON public.funding_programs FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY fp_supplier_read ON public.funding_programs FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND ((eligible_suppliers @> to_jsonb(get_user_supplier())) OR (eligible_suppliers @> to_jsonb(get_user_entity())) OR ((get_user_branch() IS NULL) AND (EXISTS ( SELECT 1
   FROM jsonb_array_elements_text(funding_programs.eligible_suppliers) es(value)
  WHERE (split_part(es.value, ':'::text, 1) = get_user_supplier())))))));

CREATE POLICY hba_internal_delete ON public.holdback_payment_allocations FOR DELETE TO public USING (is_admin());

CREATE POLICY hba_internal_insert ON public.holdback_payment_allocations FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY hba_internal_read ON public.holdback_payment_allocations FOR SELECT TO public USING (is_internal_user());

CREATE POLICY hba_internal_update ON public.holdback_payment_allocations FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY hba_supplier_read ON public.holdback_payment_allocations FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY hbp_internal_delete ON public.holdback_payments FOR DELETE TO public USING (is_admin());

CREATE POLICY hbp_internal_insert ON public.holdback_payments FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY hbp_internal_read ON public.holdback_payments FOR SELECT TO public USING (is_internal_user());

CREATE POLICY hbp_internal_update ON public.holdback_payments FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY hbp_supplier_read ON public.holdback_payments FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY invoices_buyer_read ON public.invoices FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (((get_user_branch() IS NULL) AND (buyer_id = get_user_buyer())) OR ((get_user_branch() IS NOT NULL) AND (buyer_entity_id = get_user_entity())))));

CREATE POLICY invoices_internal_delete ON public.invoices FOR DELETE TO public USING (is_admin());

CREATE POLICY invoices_internal_insert ON public.invoices FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY invoices_internal_read ON public.invoices FOR SELECT TO public USING (is_internal_user());

CREATE POLICY invoices_internal_update ON public.invoices FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY invoices_supplier_read ON public.invoices FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY pa_internal_delete ON public.payment_allocations FOR DELETE TO public USING (is_admin());

CREATE POLICY pa_internal_insert ON public.payment_allocations FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY pa_internal_read ON public.payment_allocations FOR SELECT TO public USING (is_internal_user());

CREATE POLICY pa_internal_update ON public.payment_allocations FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY pa_supplier_read ON public.payment_allocations FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY payments_buyer_read ON public.payments FOR SELECT TO public USING (((get_user_role() = 'buyer'::text) AND (((get_user_branch() IS NULL) AND (buyer_id = get_user_buyer())) OR ((get_user_branch() IS NOT NULL) AND (buyer_entity_id = get_user_entity())))));

CREATE POLICY payments_internal_delete ON public.payments FOR DELETE TO public USING (is_admin());

CREATE POLICY payments_internal_insert ON public.payments FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY payments_internal_read ON public.payments FOR SELECT TO public USING (is_internal_user());

CREATE POLICY payments_internal_update ON public.payments FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY payments_supplier_read ON public.payments FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND ((payment_id IN ( SELECT pa.payment_id
   FROM payment_allocations pa
  WHERE (((get_user_branch() IS NULL) AND (pa.supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (pa.supplier_entity_id = get_user_entity()))))) OR (payment_id IN ( SELECT spq.source_payment_id
   FROM supplier_payment_queue spq
  WHERE ((spq.type = 'remittance'::text) AND (spq.source_payment_id IS NOT NULL) AND (((get_user_branch() IS NULL) AND (spq.supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (spq.supplier_entity_id = get_user_entity())))))))));

CREATE POLICY prospect_groups_read ON public.prospect_groups FOR SELECT TO public USING ((is_internal_user() OR (get_user_role() = 'buyer'::text)));

CREATE POLICY prospect_groups_write ON public.prospect_groups FOR ALL TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text]))) WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY prospect_notes_internal_all ON public.prospect_notes FOR ALL TO authenticated USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY prospect_suppliers_internal_all ON public.prospect_suppliers FOR ALL TO authenticated USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY provider_entity_aliases_internal_delete ON public.provider_entity_aliases FOR DELETE TO public USING (is_admin());

CREATE POLICY provider_entity_aliases_internal_insert ON public.provider_entity_aliases FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY provider_entity_aliases_internal_read ON public.provider_entity_aliases FOR SELECT TO public USING (is_internal_user());

CREATE POLICY provider_entity_aliases_internal_update ON public.provider_entity_aliases FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY rate_recompute_queue_internal_all ON public.rate_recompute_queue FOR ALL TO authenticated USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY sbf_read_internal ON public.supplier_backfill FOR SELECT TO public USING (is_internal_user());

CREATE POLICY sp_internal_delete ON public.service_providers FOR DELETE TO public USING (is_admin());

CREATE POLICY sp_internal_insert ON public.service_providers FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY sp_internal_read ON public.service_providers FOR SELECT TO public USING (is_internal_user());

CREATE POLICY sp_internal_update ON public.service_providers FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY spbl_read_internal ON public.supplier_program_buyer_limit FOR SELECT TO public USING (is_internal_user());

CREATE POLICY spbo_internal ON public.supplier_program_buyer_override FOR ALL TO public USING (is_internal_user()) WITH CHECK (is_internal_user());

CREATE POLICY spq_internal_delete ON public.supplier_payment_queue FOR DELETE TO public USING (is_admin());

CREATE POLICY spq_internal_insert ON public.supplier_payment_queue FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY spq_internal_read ON public.supplier_payment_queue FOR SELECT TO public USING (is_internal_user());

CREATE POLICY spq_internal_update ON public.supplier_payment_queue FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY spq_supplier_read ON public.supplier_payment_queue FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (((get_user_branch() IS NULL) AND (supplier_id = get_user_supplier())) OR ((get_user_branch() IS NOT NULL) AND (supplier_entity_id = get_user_entity())))));

CREATE POLICY suppliers_internal_delete ON public.suppliers FOR DELETE TO public USING (is_admin());

CREATE POLICY suppliers_internal_insert ON public.suppliers FOR INSERT TO public WITH CHECK ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY suppliers_internal_read ON public.suppliers FOR SELECT TO public USING (is_internal_user());

CREATE POLICY suppliers_internal_update ON public.suppliers FOR UPDATE TO public USING ((get_user_role() = ANY (ARRAY['admin'::text, 'operations'::text])));

CREATE POLICY suppliers_supplier_read ON public.suppliers FOR SELECT TO public USING (((get_user_role() = 'supplier'::text) AND (id = get_user_supplier())));
