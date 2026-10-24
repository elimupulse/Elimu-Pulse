# Multi-school login update

This update lets one Supabase Auth user who has multiple active `school_users` memberships select which school to open after login.

## What changed
- `app.js` now loads all active school memberships instead of expecting exactly one.
- If the account belongs to multiple active schools, a school selection dialog appears.
- Cloud state continues to load/save against the selected `school_id`.
- `supabase-schema.sql` defines `school_users` with composite primary key `(user_id, school_id)` so the schema matches multi-school memberships.

## Before deploying
1. Keep a backup of the current repository and Supabase database.
2. Confirm the `school_users` primary key in Supabase is `(user_id, school_id)`.
3. Confirm each school has its own `school_state` row. The Tinet row will be initialized empty the first time it is opened, rather than copied from another school's browser cache.
4. Test with the admin account and confirm the school selector shows both schools.
5. Verify Row Level Security policies and school-scoped access before using real student or finance records.

This update does not migrate legacy records from any shared table. It only makes the existing app select the appropriate school-scoped state.
