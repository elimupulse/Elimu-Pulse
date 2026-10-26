# Elimu Pulse global-admin and tenant-isolation test plan

Run this after applying `supabase-multischool-schema.sql` (if needed) and then `supabase-global-admin-migration.sql`. Use fake data only.

## Test accounts
- Global admin: `elimu@pulse.school` (must exist in Supabase Auth and appear in `public.global_admins`).
- School A ordinary admin: one Auth account with an active `school_users` row for School A only.
- School B ordinary admin: a different Auth account with an active `school_users` row for School B only.
- Create two active test schools. Do not use real learner records.

## Expected results
1. Global admin signs in and sees the school picker. Both test schools are listed.
2. Global admin opens School A, creates a learner named `RLS TEST A - FAKE`, saves, refreshes, and sees the test record.
3. Global admin signs out, signs in again, opens School B, and does not see School A's test learner.
4. School A administrator signs in and sees only School A's data. The same test learner is visible to School A.
5. School B administrator signs in and must not see School A's learner.
6. Using School B's authenticated browser client, attempt a `select` from `school_state` filtered to School A's UUID. It must return no School A row (or an RLS denial). Attempting an update/upsert for School A must fail or affect zero rows.
7. School A cannot query the full `schools` list or other users' membership rows; it should only see its own school and its own membership.
8. Confirm that ordinary school administrators cannot access `public.global_admins` directly. Only the `is_global_admin()` RPC is callable from the authenticated client.
9. Test sign-out, sign-in, save, refresh, attendance, marks, fees and timetable with fake data.
10. Before/after migration, compare `select id, updated_at from public.school_state_shared where id='ELIMU_PULSE';` as project owner. The existing row must still be present and unchanged. The migration does not move or rewrite it.

## Important testing notes
- Run browser-client checks while signed in as each test account. SQL Editor queries execute with elevated project-owner privileges and do not prove RLS isolation.
- Do not onboard real learner data until the negative cross-school checks pass.
- The generated package has passed a JavaScript syntax check, but no live Supabase integration test was run from this environment.
- Ensure the website's Supabase Project URL and publishable key both belong to the same project where these SQL scripts were applied. Do not paste a service-role key into the website.
