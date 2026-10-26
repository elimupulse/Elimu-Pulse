-- ELIMU PULSE PLATFORM ADMINISTRATION + 30-DAY TRIALS
-- Additive migration: preserves all existing schools, users and school_state data.
-- Run after supabase-multischool-schema.sql and supabase-global-admin-migration.sql.

alter table public.schools
  add column if not exists trial_started_at timestamptz,
  add column if not exists trial_ends_at timestamptz,
  add column if not exists subscription_status text not null default 'trial',
  add column if not exists billing_cycle text not null default 'both',
  add column if not exists updated_at timestamptz not null default now();

-- Existing schools receive a 30-day trial window from migration time only when
-- they have no subscription dates; no school records or learner data are changed.
update public.schools
set trial_started_at = coalesce(trial_started_at, created_at, now()),
    trial_ends_at = coalesce(trial_ends_at, coalesce(created_at, now()) + interval '30 days'),
    subscription_status = coalesce(subscription_status, 'trial'),
    billing_cycle = coalesce(billing_cycle, 'both')
where trial_started_at is null or trial_ends_at is null;

alter table public.schools drop constraint if exists schools_subscription_status_check;
alter table public.schools add constraint schools_subscription_status_check
  check (subscription_status in ('trial','active','payment_due','suspended','expired'));
alter table public.schools drop constraint if exists schools_billing_cycle_check;
alter table public.schools add constraint schools_billing_cycle_check
  check (billing_cycle in ('monthly','annual','both'));

-- Notices are platform-owned. RLS keeps writes restricted to global admins.
create table if not exists public.platform_notices (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null,
  notice_type text not null default 'announcement' check (notice_type in ('announcement','payment_reminder','maintenance')),
  school_id uuid references public.schools(id) on delete cascade,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.school_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'KES',
  billing_cycle text not null check (billing_cycle in ('monthly','annual')),
  payment_method text not null default 'manual' check (payment_method in ('manual','mpesa')),
  reference text,
  payment_status text not null default 'pending' check (payment_status in ('pending','confirmed','rejected')),
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.platform_notices enable row level security;
alter table public.school_payments enable row level security;
drop policy if exists platform_notices_global_admin_all on public.platform_notices;
create policy platform_notices_global_admin_all on public.platform_notices
  for all to authenticated using (public.is_global_admin()) with check (public.is_global_admin());
drop policy if exists school_payments_global_admin_all on public.school_payments;
create policy school_payments_global_admin_all on public.school_payments
  for all to authenticated using (public.is_global_admin()) with check (public.is_global_admin());
revoke all on public.platform_notices, public.school_payments from anon, authenticated;
grant select, insert, update, delete on public.platform_notices, public.school_payments to authenticated;

-- The Edge Function uses the service role only on the server. Do not add it to app.js.
