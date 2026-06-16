# TEACHING-APP / Supabase migration TODO

## Step 1 — Create Supabase schema
- Generate SQL for required tables using snake_case naming.
- Ensure unique constraints:
  - users.username
  - admins.username
  - course_progress (student_id, course_id)
- Ensure foreign keys between tables.

## Step 2 — Update backend to use Supabase
- Update `backend/server.js`:
  - remove mongoose connection
  - initialize `@supabase/supabase-js` client using env vars

## Step 3 — Migrate DB calls route-by-route
- Update these routes to replace mongoose queries with Supabase queries:
  - `backend/routes/auth.js`
  - `backend/routes/course.js`
  - `backend/routes/enrollment.js`
  - `backend/routes/progress.js`
  - `backend/routes/video.js` (DB only; keep local uploads for now)
  - `backend/routes/liveClassRoutes.js`
  - `backend/routes/settings.js`
  - `backend/routes/imageUrl.js`

## Step 4 — Verify API compatibility
- Ensure response shapes remain identical to current frontend expectations.
- Ensure JWT claims and auth middleware still work.

## Step 5 — Run and test
- Start backend and test key flows:
  - register/login
  - list courses
  - create enrollment
  - get/update progress
  - settings + image URLs
  - live class access
  - videos public/admin

