-- =========================================================================
-- CAI Courseware Database Setup Script for Supabase
-- Subject: Computing Science (ว 42202) - Augmented Reality (AR)
-- =========================================================================

-- 1. Enable Required Extensions
create extension if not exists "pgcrypto";

-- 2. Drop Existing Objects (Clean Slate Strategy)
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_student_signup();
drop function if exists public.is_teacher();
drop view if exists public.results;
drop table if exists public.materials cascade;
drop table if exists public.submissions cascade;
drop table if exists public.progress cascade;
drop table if exists public.attempts cascade;
drop table if exists public.students cascade;
drop table if exists public.teachers cascade;

-- 3. Create Tables

-- Teachers Table
create table public.teachers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- Students Table (Initial Seeded Roster)
create table public.students (
  id varchar(11) primary key,
  title text not null,
  first_name text not null,
  last_name text not null,
  section text not null,
  user_id uuid references auth.users(id) on delete set null,
  photo_path text,
  created_at timestamptz default now()
);

-- Attempts Table (Pre/Post Test Scores)
create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('pre', 'post')),
  score numeric not null check (score >= 0 and score <= 10),
  answers jsonb not null,
  created_at timestamptz default now(),
  constraint attempts_user_kind_unique unique(user_id, kind)
);

-- Progress Table (Lesson Unit Completion)
create table public.progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  unit integer not null check (unit between 1 and 5),
  done boolean default true,
  created_at timestamptz default now(),
  constraint progress_user_unit_unique unique(user_id, unit)
);

-- Submissions Table (AR Hands-on Assignments)
create table public.submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  unit integer not null check (unit between 1 and 5),
  kind text check (kind in ('link', 'file')),
  url text,
  storage_path text,
  note text,
  score numeric check (score >= 0 and score <= 100),
  teacher_comment text,
  created_at timestamptz default now()
);

-- Materials Table (Teacher Uploaded Courseware Materials)
create table public.materials (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  kind text check (kind in ('file', 'link', 'video')),
  url text,
  storage_path text,
  file_name text,
  created_at timestamptz default now()
);

-- 4. Helper Function: Check if user is a teacher
create or replace function public.is_teacher()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return exists (
    select 1 from public.teachers where user_id = auth.uid()
  );
end;
$$;

-- 5. Trigger Function: Student Signup Verification
create or replace function public.handle_student_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  student_id_val text;
  found_student record;
begin
  -- Check if email matches student format (11 digits prefix)
  if new.email ~ '^[0-9]{11}@' then
    student_id_val := split_part(new.email, '@', 1);
    
    select * into found_student from public.students where id = student_id_val;
    
    if not found then
      raise exception 'รหัสนักเรียน % ไม่มีอยู่ในรายชื่อผู้มีสิทธิ์เรียน', student_id_val;
    end if;
    
    if found_student.user_id is not null then
      raise exception 'รหัสนักเรียน % ได้ถูกลงทะเบียนไปแล้ว', student_id_val;
    end if;
    
    update public.students set user_id = new.id where id = student_id_val;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_student_signup();

-- 6. Row Level Security (RLS) & Security Policies

-- Enable RLS on all tables
alter table public.teachers enable row level security;
alter table public.students enable row level security;
alter table public.attempts enable row level security;
alter table public.progress enable row level security;
alter table public.submissions enable row level security;
alter table public.materials enable row level security;

-- Revoke default public permissions
revoke all on public.teachers from anon, authenticated;
revoke all on public.students from anon, authenticated;
revoke all on public.attempts from anon, authenticated;
revoke all on public.progress from anon, authenticated;
revoke all on public.submissions from anon, authenticated;
revoke all on public.materials from anon, authenticated;

-- Grant selective table permissions to authenticated users
grant select on public.teachers to authenticated;
grant select, insert on public.students to authenticated;
grant select, insert on public.attempts to authenticated;
grant select, insert, update on public.progress to authenticated;
grant select, insert on public.submissions to authenticated;
grant select, insert, update, delete on public.materials to authenticated;

-- Column-level Security for Updating
-- Students can ONLY update photo_path in students table
grant update (photo_path) on public.students to authenticated;
-- Teachers can UPDATE score & teacher_comment in submissions
grant update (score, teacher_comment) on public.submissions to authenticated;

-- RLS Policies: teachers
create policy "Teachers read policy" on public.teachers
  for select to authenticated using (is_teacher());

-- RLS Policies: students
create policy "Students select own or teacher selects all" on public.students
  for select to authenticated using (auth.uid() = user_id or is_teacher());

create policy "Students update own photo_path" on public.students
  for update to authenticated using (auth.uid() = user_id or is_teacher());

-- RLS Policies: attempts
create policy "Attempts select own or teacher selects all" on public.attempts
  for select to authenticated using (auth.uid() = user_id or is_teacher());

create policy "Students insert own attempts" on public.attempts
  for insert to authenticated with check (auth.uid() = user_id);

-- RLS Policies: progress
create policy "Progress select own or teacher selects all" on public.progress
  for select to authenticated using (auth.uid() = user_id or is_teacher());

create policy "Students insert own progress" on public.progress
  for insert to authenticated with check (auth.uid() = user_id);

create policy "Students update own progress" on public.progress
  for update to authenticated using (auth.uid() = user_id);

-- RLS Policies: submissions
create policy "Submissions select own or teacher selects all" on public.submissions
  for select to authenticated using (auth.uid() = user_id or is_teacher());

create policy "Students insert own submissions" on public.submissions
  for insert to authenticated with check (auth.uid() = user_id);

create policy "Teachers update submission score and comment" on public.submissions
  for update to authenticated using (is_teacher());

-- RLS Policies: materials
create policy "All authenticated users view materials" on public.materials
  for select to authenticated using (true);

create policy "Teachers manage materials" on public.materials
  for all to authenticated using (is_teacher()) with check (is_teacher());

-- 7. View for Teacher Results Summary
create view public.results with (security_invoker = true) as
select 
  s.id as student_id,
  s.title,
  s.first_name,
  s.last_name,
  s.section,
  s.photo_path,
  s.user_id,
  (select count(*) from public.progress p where p.user_id = s.user_id and p.done = true) as units_completed,
  a_pre.score as pre_score,
  a_post.score as post_score,
  case 
    when a_pre.score is not null and a_post.score is not null then
      case 
        when a_pre.score >= 10 then 1.00
        else round((a_post.score - a_pre.score)::numeric / (10 - a_pre.score)::numeric, 4)
      end
    else null
  end as normalized_gain
from public.students s
left join public.attempts a_pre on s.user_id = a_pre.user_id and a_pre.kind = 'pre'
left join public.attempts a_post on s.user_id = a_post.user_id and a_post.kind = 'post';

grant select on public.results to authenticated;

-- 8. Storage Buckets Setup
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values 
  ('photos', 'photos', false, 2097152, array['image/png', 'image/jpeg']),
  ('submissions', 'submissions', false, 20971520, array['image/png', 'image/jpeg', 'application/pdf', 'video/mp4']),
  ('materials', 'materials', false, 52428800, array['application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/pdf'])
on conflict (id) do update set 
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Storage RLS Policies
create policy "Photos owner access and teacher read" on storage.objects
  for select to authenticated using (
    bucket_id = 'photos' and (
      (storage.foldername(name))[1] = auth.uid()::text or public.is_teacher()
    )
  );

create policy "Photos owner upload/delete" on storage.objects
  for all to authenticated using (
    bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text
  ) with check (
    bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Submissions owner upload and teacher read" on storage.objects
  for select to authenticated using (
    bucket_id = 'submissions' and (
      (storage.foldername(name))[1] = auth.uid()::text or public.is_teacher()
    )
  );

create policy "Submissions owner insert" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'submissions' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Materials read all authenticated" on storage.objects
  for select to authenticated using (bucket_id = 'materials');

create policy "Materials teacher write" on storage.objects
  for all to authenticated using (
    bucket_id = 'materials' and public.is_teacher()
  ) with check (
    bucket_id = 'materials' and public.is_teacher()
  );

-- 9. Seed Data: 6 Initial Mock Students
-- หมายเหตุสำหรับการนำเข้ารายชื่อจริง: ผู้สอนสามารถนำเข้าข้อมูล CSV ผ่าน Supabase Dashboard -> Table Editor -> students -> Insert -> Import data from CSV
insert into public.students (id, title, first_name, last_name, section) values
('66010000001', 'นาย', 'สมชาย', 'ใจดี', 'Sec 1'),
('66010000002', 'นางสาว', 'สมหญิง', 'รักเรียน', 'Sec 1'),
('66010000003', 'นาย', 'กิตติ', 'เก่งกาจ', 'Sec 1'),
('66010000004', 'นางสาว', 'ปรียา', 'มีสุข', 'Sec 2'),
('66010000005', 'นาย', 'ธนกฤต', 'ยอดเยี่ยม', 'Sec 2'),
('66010000006', 'นางสาว', 'ณิชา', 'งามสง่า', 'Sec 2')
on conflict (id) do nothing;

-- =========================================================================
-- การแต่งตั้งบัญชีผู้สอน (Teacher Account Configuration)
-- คำแนะนำ:
-- 1. ผู้สอนสมัครสมาชิกผ่านหน้าเว็บด้วยอีเมลอาจารย์ (เช่น teacher@school.ac.th)
-- 2. คัดลอก User ID (UUID) จาก Supabase Dashboard -> Authentication -> Users
-- 3. นำ UUID มาแทนที่ '00000000-0000-0000-0000-000000000000' แล้วปลดคอมเมนต์บรรทัดล่างสุดเพื่อรันคำสั่ง
-- =========================================================================

-- insert into public.teachers (user_id) values ('00000000-0000-0000-0000-000000000000');