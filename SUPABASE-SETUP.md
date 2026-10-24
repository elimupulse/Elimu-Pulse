# Elimu Pulse — Multi-school Supabase setup (Option A)

## Before you begin
Back up existing data. The legacy `school_state_shared` record is not automatically migrated because the correct owning school must be confirmed.

## 1. Install the schema
In Supabase Dashboard → SQL Editor, run `supabase-multischool-schema.sql`. This creates:
- `schools`: one record per school
- `school_users`: maps each Auth user to one school and role
- `school_state`: one JSON state row per school
- RLS policies that check the logged-in user's active membership

The script also revokes browser access to the legacy `school_state_shared` table.

## 2. Create a school and its administrator
First create the administrator in Authentication → Users. Use a unique email and strong temporary password. Copy the Auth user UUID.

Then run the following in SQL Editor, replacing the example values:

```sql
insert into public.schools (name, school_code)
values ('Kapnanda Primary School', 'KAPNANDA-001')
returning id;

-- Copy the returned school UUID and the Auth user UUID:
insert into public.school_users (user_id, school_id, role)
values ('AUTH-USER-UUID-HERE', 'SCHOOL-UUID-HERE', 'school_admin');
```

Repeat for each school. Do not reuse a school UUID or assign one account to multiple schools in this initial setup. The administrator must change the temporary password after first sign-in.

## 3. Deploy
The supplied `app.js` uses the Supabase URL and publishable key configured in the file. The publishable key is designed for browser use; never put a service-role or secret key in frontend files.

Deploy the updated `app.js` together with the existing `index.html`, `style.css`, and other project assets.

## 4. Test before onboarding real learner data
1. Create two test schools and two Auth users.
2. Assign each user to only one school.
3. Sign in as School A, add a clearly fake test learner, and sign out.
4. Sign in as School B and verify the learner is not visible.
5. Try reading or updating School A's UUID as School B using the browser client; RLS should deny it.
6. Test saving marks, fees, attendance, timetable, reports, logout and password reset.

## Important
The app stores its module data as a JSON object per school. This retains the existing modules without a large rewrite, but concurrent edits to the same school state may still need further conflict handling. Do not treat this as fully production-audited until cross-school tests have passed.


## 5. Add authorized global administration (preserves existing data)
1. Back up the database before changing access policies.
2. In Supabase SQL Editor, run `supabase-global-admin-migration.sql` as the project owner.
3. The script adds `public.global_admins` and the `is_global_admin()` RPC. It authorizes the existing Auth account `elimu@pulse.school` only if that account exists. It does not assign a school membership, copy legacy data, or alter `school_state_shared`.
4. Sign in as `elimu@pulse.school`; the app should show a school picker. Select a school to open its school-scoped data.
5. Normal school administrators still need an active `school_users` membership and can only read/write their assigned school's `school_state`.
6. To authorize another global administrator, create their Auth account, then insert that user's Auth UUID into `public.global_admins` using the SQL Editor. Never expose a service-role key in the browser.

## 6. Isolation test before real data
Use two test schools and two ordinary test users, plus the global-admin test account. Use fake learner data only.
- School A user: confirm only School A is listed/accessible and can save its test record.
- School B user: confirm School A's state cannot be read or updated using the browser client.
- Global admin: confirm both schools are selectable and their records load separately.
- Confirm the `ELIMU_PULSE` row in `school_state_shared` has the same ID and `updated_at` as before. Do not copy or assign that record to any school until its owner is explicitly confirmed.
- Test login, logout, save, refresh, and role changes. This package includes a checklist; it does not claim that a live Supabase isolation test has been run.
