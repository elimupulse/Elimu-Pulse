# Elimu Pulse — Kapnanda-faithful rebuild notes

- Source baseline: supplied `Kapnanda-Comprehensive-School--main.zip`.
- Retained the original application code, UI stylesheet, module pages, reports, rankings, print/PDF workflows, timetable tools, CSV import, question paper generator, TPAD sub-application and setup documents.
- Rebranded UI and project documentation to Elimu Pulse.
- Removed the hard-coded Kapnanda Supabase URL and publishable key; backend config is intentionally blank to prevent data going to the original school's backend.
- Changed the initial shared-state key to `ELIMU_PULSE`.
- SQL initial state starts with empty learners and teachers and empty transaction arrays. No learner or teacher records are packaged.
- This is a faithful rebrand of the supplied Kapnanda build, not yet a production multi-tenant SaaS conversion. The shared-state architecture needs tenant isolation before multiple schools can safely share a backend.
