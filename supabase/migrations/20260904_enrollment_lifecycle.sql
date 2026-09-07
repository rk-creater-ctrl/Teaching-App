-- Adds a reject-and-reapply lifecycle without changing historical rejected rows.
alter table public.enrollments
  drop constraint if exists enrollments_status_check;

alter table public.enrollments
  add constraint enrollments_status_check
  check (status in ('pending', 'active', 'completed', 'rejected'));

-- One current enrollment per student/course. Rejected applications remain as history.
create unique index if not exists enrollments_one_current_per_course_idx
  on public.enrollments (student_id, course_id)
  where status <> 'rejected';
