-- ELIMU PULSE GLOBAL ADMIN ACCESS MIGRATION
-- Additive, repeatable migration. Does NOT delete, move, import, or rewrite school data.
-- Run in Supabase SQL Editor as project owner after backing up the database.
-- Global admin authority is stored server-side, never inferred from email in app.js.

begin;

create table if not exists public.global_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.global_admins enable row level security;
revoke all on public.global_admins from anon, authenticated;

create or replace function public.is_global_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select exists (
    select 1
    from public.global_admins ga
    where ga.user_id = auth.uid()
  );
$function$;

revoke all on function public.is_global_admin() from public, anon;
grant execute on function public.is_global_admin() to authenticated;

-- Seed only the explicitly identified existing Auth account (UUID and email must both match).
-- If it is absent, this inserts nothing; create/confirm the Auth user before rerunning.
insert into public.global_admins (user_id)
select u.id
from auth.users u
where u.id = '868e8202-b3af-496f-8f9e-55dd2f5b23ab'::uuid
  and lower(u.email) = lower('shadrackkorir644@gmail.com')
on conflict (user_id) do nothing;

-- Verify the exact account was found and authorized:
-- select u.id, u.email, ga.created_at
-- from public.global_admins ga
-- join auth.users u on u.id = ga.user_id
-- where u.id = '868e8202-b3af-496f-8f9e-55dd2f5b23ab'::uuid;

-- Rebuild policies on tenant tables from a known-safe set. This removes any stale
-- permissive policy that might otherwise allow cross-school access. Rows are untouched.
do $drop_policies$
declare p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('schools','school_users','school_state')
  loop
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
  end loop;
end
$drop_policies$;

-- Normal members can only see their own school and their own membership.
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

-- Global-admin policies are separate exceptions to the member-only policies.
drop policy if exists global_admin_schools_select on public.schools;
create policy global_admin_schools_select
on public.schools for select to authenticated
using (public.is_global_admin());

drop policy if exists global_admin_school_users_select on public.school_users;
create policy global_admin_school_users_select
on public.school_users for select to authenticated
using (public.is_global_admin());

drop policy if exists global_admin_school_state_select on public.school_state;
create policy global_admin_school_state_select
on public.school_state for select to authenticated
using (public.is_global_admin());

drop policy if exists global_admin_school_state_insert on public.school_state;
create policy global_admin_school_state_insert
on public.school_state for insert to authenticated
with check (public.is_global_admin());

drop policy if exists global_admin_school_state_update on public.school_state;
create policy global_admin_school_state_update
on public.school_state for update to authenticated
using (public.is_global_admin())
with check (public.is_global_admin());

-- Ensure browser roles have only the intended operations. No DELETE is granted.
grant select on public.schools to authenticated;
grant select on public.school_users to authenticated;
grant select, insert, update on public.school_state to authenticated;

commit;

-- Verification queries (run after migration):
-- 1. Confirm global admin seed exists (as project owner):
-- select u.email, ga.user_id, ga.created_at
-- from public.global_admins ga join auth.users u on u.id = ga.user_id;
--
-- 2. Confirm existing legacy data was not touched:
-- select id, updated_at from public.school_state_shared where id = 'ELIMU_PULSE';
--
-- 3. Confirm policies exist:
-- select schemaname, tablename, policyname, cmd
-- from pg_policies
-- where schemaname='public'
-- and tablename in ('global_admins','schools','school_users','school_state')
-- order by tablename, policyname;
