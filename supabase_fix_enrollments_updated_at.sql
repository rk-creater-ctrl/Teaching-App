-- Fix production enrollment updates failing with PostgreSQL error 42703:
-- record "new" has no field "updated_at"
alter table public.enrollments
  add column if not exists updated_at timestamptz not null default now();

