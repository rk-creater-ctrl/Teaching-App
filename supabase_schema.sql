-- Supabase schema for SR EduNova
-- Naming: snake_case tables/columns.
-- NOTE: Run this in Supabase SQL editor.

-- Extensions (optional but harmless)
-- create extension if not exists pgcrypto;

-- -------------------------
-- Users (students)
-- -------------------------
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  username text not null unique,
  password_hash text not null,
  role text not null default 'student' check (role in ('student','admin','teacher')),
  created_at timestamptz not null default now()
);

-- -------------------------
-- Admins
-- -------------------------
create table if not exists public.admins (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  username text not null unique,
  password_hash text not null,
  level text not null default 'super_admin' check (level in ('super_admin','admin')),
  created_by uuid references public.admins(id) on delete set null,
  created_from_user uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- -------------------------
-- Courses
-- -------------------------
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  cover_image_url text,
  category text,
  is_paid boolean not null default false,
  price numeric not null default 0,
  mode_options_online boolean not null default true,
  mode_options_offline boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists courses_created_at_idx on public.courses(created_at desc);

-- Optional trigger to keep updated_at current
create or replace function public.set_updated_at()
returns trigger as $$
begin
  NEW.updated_at = now();
  return NEW;
end;
$$ language plpgsql;

drop trigger if exists trg_courses_updated_at on public.courses;
create trigger trg_courses_updated_at
before update on public.courses
for each row execute function public.set_updated_at();

-- -------------------------
-- Enrollments
-- -------------------------
create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,

  mode text not null check (mode in ('online','offline')),
  status text not null default 'pending' check (status in ('pending','active','completed')),

  payment_type text check (payment_type in ('online','offline')),
  payment_status text not null default 'unpaid' check (payment_status in ('unpaid','paid')),

  amount numeric not null default 0,

  offline_address text,
  offline_teacher_name text,
  offline_phone text,
  offline_message text,

  online_order_id text,
  online_payment_id text,
  online_signature text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists enrollments_student_id_idx on public.enrollments(student_id);
create index if not exists enrollments_course_id_idx on public.enrollments(course_id);

-- update trigger for enrollments
drop trigger if exists trg_enrollments_updated_at on public.enrollments;
create trigger trg_enrollments_updated_at
before update on public.enrollments
for each row execute function public.set_updated_at();

-- -------------------------
-- Course Progress
-- matches: CourseProgressSchema
-- unique (student_id, course_id)
-- -------------------------
create table if not exists public.course_progress (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  completed_lesson_ids text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint course_progress_student_course_unique unique (student_id, course_id)
);

create index if not exists course_progress_student_id_idx on public.course_progress(student_id);

-- update trigger for course_progress
drop trigger if exists trg_course_progress_updated_at on public.course_progress;
create trigger trg_course_progress_updated_at
before update on public.course_progress
for each row execute function public.set_updated_at();

-- -------------------------
-- Live Class (single global row by key='global')
-- -------------------------
create table if not exists public.live_classes (
  id uuid primary key default gen_random_uuid(),
  "key" text not null default 'global' unique,

  title text not null,
  status text not null default 'scheduled' check (status in ('scheduled','live','ended')),
  scheduled_at timestamptz,

  youtube_video_id text,

  active_mode text not null default 'internal' check (active_mode in ('youtube','internal')),

  internal_live_active boolean not null default false,
  internal_room_code text,
  internal_live_started_at timestamptz,
  internal_live_ended_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- update trigger for live_classes
drop trigger if exists trg_live_classes_updated_at on public.live_classes;
create trigger trg_live_classes_updated_at
before update on public.live_classes
for each row execute function public.set_updated_at();

-- -------------------------
-- Videos
-- -------------------------
create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  "type" text not null default 'youtube' check ("type" in ('youtube','file')),
  youtube_video_id text,
  file_url text,
  "order" integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists videos_order_idx on public.videos("order" asc, created_at desc);

-- update trigger for videos
drop trigger if exists trg_videos_updated_at on public.videos;
create trigger trg_videos_updated_at
before update on public.videos
for each row execute function public.set_updated_at();

-- -------------------------
-- Image URLs
-- -------------------------
create table if not exists public.image_urls (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  url text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- update trigger for image_urls
drop trigger if exists trg_image_urls_updated_at on public.image_urls;
create trigger trg_image_urls_updated_at
before update on public.image_urls
for each row execute function public.set_updated_at();

-- -------------------------
-- App Settings
-- -------------------------
create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  "key" text not null default 'global' unique,
  brand_name text not null default 'SR EduNova',
  app_name text not null default 'SR EduNova',
  institute_name text not null default 'Your Institute Name',
  logo_url text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- update trigger for app_settings
drop trigger if exists trg_app_settings_updated_at on public.app_settings;
create trigger trg_app_settings_updated_at
before update on public.app_settings
for each row execute function public.set_updated_at();

-- -------------------------
-- RLS notes (IMPORTANT)
-- Your backend will use the Service Role key, so RLS can be off for development.
-- If you enable RLS, you must create policies.
-- -------------------------
-- alter table public.users enable row level security;
-- ... (policies not included here)

