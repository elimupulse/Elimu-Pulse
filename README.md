# Elimu Pulse School Management System

Elimu Pulse is a rebranded build of the supplied Kapnanda Comprehensive School Management System. The supplied application modules, interface, reports, ranking layouts, PDF/print flows, attendance, fees, timetables, settings, backup, audit, parent contacts, bulk messaging, school controls, alumni, and TPAD assistant have been retained rather than replaced with a smaller prototype.

## Included modules
- Dashboard and school settings
- Learners and CSV admission/import
- Alumni register and school controls
- Teachers and teacher/class/subject assignments
- Marks and exams
- AI-assisted question-paper generator
- EE1, EE2, ME1, ME2, AE1, AE2, BE1, BE2 grading terminology
- Class rankings, 9-subject performance ranking, grade distribution, learner positions
- A4 individual learner reports, print-all reports, class-report PDF download
- Attendance register (Present / Late / Absent)
- School performance analytics
- Fees and academic periods
- Teacher-aware timetables and class/teacher/all-school PDF exports
- Subjects, parent/guardian contacts and CSV tools
- Bulk messaging (SMS/WhatsApp setup guide)
- Backup, audit and settings
- TPAD assistant in `tpad/`

## Multi-school Supabase setup (Option A: owner creates accounts)
The app uses one `school_state` row per school and requires each Auth user to be assigned to a school in `school_users`. Database Row Level Security (RLS) enforces this assignment.

1. Back up existing data before changing your database.
2. In Supabase SQL Editor, run `supabase-multischool-schema.sql` (also copied to `supabase-schema.sql`). This locks down the legacy `school_state_shared` table; it does not migrate its old contents.
3. In Supabase Dashboard → Authentication → Users, create a unique administrator account for each school. Use a strong temporary password and deliver it privately.
4. For each school, run `insert into public.schools (name, school_code) values ('School Name', 'UNIQUE-CODE') returning id;` and copy the returned school UUID.
5. Copy the administrator's Auth user UUID and insert a membership: `insert into public.school_users (user_id, school_id, role) values ('AUTH-USER-UUID', 'SCHOOL-UUID', 'school_admin');`
6. Deploy the updated project files over HTTPS.
7. Test with two separate school accounts. Confirm each account only sees its own data.

`app.js` uses the project's URL and publishable key only. Never place a Supabase service-role/secret key in browser code. Existing legacy data in `school_state_shared` is intentionally not automatically migrated; first decide which school owns it, then migrate it deliberately after backup.

## Security notes
- There is no public school sign-up. Only the project owner should create schools, Auth users and memberships.
- An authenticated account without an active `school_users` row is denied access.
- School data isolation is enforced by RLS, not just by a client-side school ID.
- This update preserves the existing JSON data format and app modules. For very large deployments, normalised per-module tables may be preferable later.

## Bulk learner import
Learner CSV import is available in the Learners section. The source application expects headers `admission_number`, `learner_name`, and `grade`; `assessment_number` is optional. Review the import preview before confirming. Do not commit real learner information to a public repository.

## Deployment
Serve `index.html` over HTTPS. Open `index.html` directly only for a quick visual check; authentication and cloud sync require the Supabase configuration above.

See `DEPLOYMENT-CHECKLIST.md`, `SECURITY.md`, `SUPABASE-SETUP.md`, `BULK-MESSAGING-SETUP.md`, and the TPAD documentation for setup guidance.
