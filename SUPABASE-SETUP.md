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
