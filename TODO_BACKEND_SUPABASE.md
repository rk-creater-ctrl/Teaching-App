# Backend -> Supabase migration checklist

## Prereqs
- [ ] Create Supabase project
- [ ] Copy env vars into `backend/.env`:
  - SUPABASE_URL
  - SUPABASE_ANON_KEY
  - SUPABASE_SERVICE_ROLE_KEY

## SQL
- [x] Create `supabase_schema.sql`
- [ ] Run SQL in Supabase SQL editor

## Backend code updates
- [ ] Install dependency `@supabase/supabase-js`
- [ ] Update `backend/server.js`:
  - remove mongoose connect
  - initialize supabase client
  - export client to routes or pass via module
- [ ] Create `backend/supabaseClient.js` utility module

## Route migrations (replace mongoose calls)
- [ ] routes/auth.js (users/admins username lookup + create + update me)
- [ ] routes/course.js
- [ ] routes/enrollment.js
- [ ] routes/progress.js
- [ ] routes/liveClassRoutes.js
- [ ] routes/video.js (DB only; keep local upload)
- [ ] routes/settings.js
- [ ] routes/imageUrl.js

## Testing
- [ ] Start backend
- [ ] Smoke test endpoints from React/Flutter:
  - /auth/register, /auth/login, /auth/me
  - /course/list, /course/:id
  - /enrollment, /enrollment/my-fees/:studentId
  - /progress/:studentId, /progress/:studentId/:courseId, PUT update
  - /settings/public
  - /live-class/student/:studentId
  - /video/public

