-- Keep existing objects and paths; only change bucket visibility.
insert into storage.buckets (id, name, public)
values
  ('course-videos', 'course-videos', false),
  ('course-materials', 'course-materials', false)
on conflict (id) do update set public = false;
