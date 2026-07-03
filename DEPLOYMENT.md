# Deploy to Render and Vercel

## 1. Backend repository

`backend/` is a Git submodule. Commit and push its current changes to
`https://github.com/rk-creater-ctrl/backend-.git` first, then commit the updated
submodule reference in this repository. Never commit `backend/.env`; configure
secrets in Render instead.

## 2. Render backend

Create a Render Blueprint from this repository. Render reads `render.yaml`.
Set these values in Render:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `FRONTEND_URLS` (the Vercel URL; comma-separate multiple URLs)
- `BASE_URL` (the Render service URL)
- Razorpay keys if payments are enabled

Render generates `JWT_SECRET`. Keep it stable or existing login tokens will
become invalid.

## 3. Vercel admin frontend

Import this repository and set Root Directory to `admin-web`. Set
`VITE_API_URL` to the Render service URL. Build command is `npm run build` and
the output directory is `dist`.

## 4. Student Flutter app

```sh
flutter build web --dart-define=API_URL=https://your-render-service.onrender.com
```

## Storage warning

Render's local filesystem is ephemeral. Files under `backend/uploads/` can
disappear after a restart or redeploy. Use Supabase Storage for durable
production image and video uploads.
