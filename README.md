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

## Empty starting data
The included `supabase-schema.sql` creates the initial Elimu Pulse state with empty learner and teacher arrays, and empty marks, attendance, fees/payment, timetable and other transactional records. No learners or teachers are bundled. Create staff sign-in accounts yourself in your own Supabase project's Authentication panel.

## Required backend setup before first use
This package intentionally does **not** point to the original Kapnanda Supabase project. Configure your own Supabase project so Elimu Pulse data is separate.

1. Create a Supabase project owned by your school/organisation.
2. Open `app.js` and set `url` and `anonKey` in the cloud config to your project's URL and publishable/anon key. Never use a service-role key in browser code.
3. Run `supabase-schema.sql` in your project's SQL editor.
4. Create authorised staff users in Supabase Authentication.
5. Deploy the static files to your HTTPS host and test login, data save/load, CSV import, reports, PDF and print flows.

**Important security note:** The supplied Kapnanda application uses a single shared state row with authenticated-user access. It is suitable as a faithful single-school starting point, but it is not yet a secure multi-school SaaS tenant-isolation model. Do not onboard multiple unrelated schools to the same backend until tenant-level school IDs, role checks, and row-level security policies are implemented and security-tested.

## Bulk learner import
Learner CSV import is available in the Learners section. The source application expects headers `admission_number`, `learner_name`, and `grade`; `assessment_number` is optional. Review the import preview before confirming. Do not commit real learner information to a public repository.

## Deployment
Serve `index.html` over HTTPS. Open `index.html` directly only for a quick visual check; authentication and cloud sync require the Supabase configuration above.

See `DEPLOYMENT-CHECKLIST.md`, `SECURITY.md`, `SUPABASE-SETUP.md`, `BULK-MESSAGING-SETUP.md`, and the TPAD documentation for setup guidance.
