-- ELIMU PULSE MULTI-SCHOOL TENANT ISOLATION
-- Run this in Supabase SQL Editor as project owner.
-- This replaces browser access to the legacy shared state table with school-scoped rows.
-- Never put a service_role key in app.js.

create extension if not exists pgcrypto;

create table if not exists public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  school_code text unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.school_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  school_id uuid not null references public.schools(id) on delete restrict,
  role text not null default 'school_admin'
    check (role in ('school_admin','teacher','bursar','viewer')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists school_users_school_id_idx
  on public.school_users(school_id);

create table if not exists public.school_state (
  school_id uuid primary key references public.schools(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.schools enable row level security;
alter table public.school_users enable row level security;
alter table public.school_state enable row level security;

-- Remove any previous policies so this migration is repeatable and restrictive.
drop policy if exists schools_read_member on public.schools;
drop policy if exists school_users_read_self on public.school_users;
drop policy if exists school_state_select_member on public.school_state;
drop policy if exists school_state_insert_member on public.school_state;
drop policy if exists school_state_update_member on public.school_state;

create policy schools_read_member
on public.schools for select to authenticated
using (
  exists (
    select 1 from public.school_users su
    where su.user_id = (select auth.uid())
      and su.school_id = schools.id
      and su.is_active = true
  )
);

create policy school_users_read_self
on public.school_users for select to authenticated
using (user_id = (select auth.uid()) and is_active = true);

create policy school_state_select_member
on public.school_state for select to authenticated
using (
  exists (
    select 1 from public.school_users su
    join public.schools s on s.id = su.school_id
    where su.user_id = (select auth.uid())
      and su.school_id = school_state.school_id
      and su.is_active = true and s.is_active = true
  )
);

create policy school_state_insert_member
on public.school_state for insert to authenticated
with check (
  exists (
    select 1 from public.school_users su
    join public.schools s on s.id = su.school_id
    where su.user_id = (select auth.uid())
      and su.school_id = school_state.school_id
      and su.is_active = true and s.is_active = true
  )
);

create policy school_state_update_member
on public.school_state for update to authenticated
using (
  exists (
    select 1 from public.school_users su
    join public.schools s on s.id = su.school_id
    where su.user_id = (select auth.uid())
      and su.school_id = school_state.school_id
      and su.is_active = true and s.is_active = true
  )
)
with check (
  exists (
    select 1 from public.school_users su
    join public.schools s on s.id = su.school_id
    where su.user_id = (select auth.uid())
      and su.school_id = school_state.school_id
      and su.is_active = true and s.is_active = true
  )
);

-- Minimum browser privileges. Memberships and schools are managed by the owner
-- through Supabase SQL Editor/Auth dashboard, not by public sign-up screens.
revoke all on public.schools from anon, authenticated;
revoke all on public.school_users from anon, authenticated;
revoke all on public.school_state from anon, authenticated;
grant select on public.schools to authenticated;
grant select on public.school_users to authenticated;
grant select, insert, update on public.school_state to authenticated;

-- Lock down the old shared table if it exists. It must not remain accessible
-- because its former policies allowed every authenticated user to see all data.
do $$
begin
  if to_regclass('public.school_state_shared') is not null then
    execute 'alter table public.school_state_shared enable row level security';
    execute 'drop policy if exists school_state_shared_select_auth on public.school_state_shared';
    execute 'drop policy if exists school_state_shared_insert_auth on public.school_state_shared';
    execute 'drop policy if exists school_state_shared_update_auth on public.school_state_shared';
    execute 'revoke all on public.school_state_shared from anon, authenticated';
  end if;
end $$;

-- --------------------------------------------------------------------
-- OWNER WORKFLOW FOR EACH NEW SCHOOL
-- 1. Create school row (change the name and code):
-- insert into public.schools (name, school_code)
-- values ('Example Primary School', 'EXAMPLE-001') returning id;
--
-- 2. In Supabase Dashboard > Authentication > Users, create the school's
--    administrator user with their unique email and a strong temporary password.
--    Copy the Auth user's UUID.
--
-- 3. Assign that Auth user to the school using the returned school UUID:
-- insert into public.school_users (user_id, school_id, role)
-- values ('AUTH-USER-UUID-HERE', 'SCHOOL-UUID-HERE', 'school_admin');
--
-- The account cannot access the app until it has an active school_users row.
-- Create each school and its admin separately. Never share passwords.
-- --------------------------------------------------------------------
