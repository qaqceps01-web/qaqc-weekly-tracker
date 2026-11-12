-- QA/QC Weekly Meeting Tracker
-- Run this once in the Supabase SQL Editor of your new project.
-- Email-whitelist gate (no password / no OTP): whitelist enforced in frontend
-- `index.html` via localStorage; RLS is open (anon can read/write) to allow
-- email-only access without Supabase Auth session. Keep RLS enabled for
-- Realtime + future hardening.

create table if not exists public.weeks (
  id text primary key,
  label text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  id text primary key,
  week_id text not null references public.weeks(id) on delete cascade,
  cat text not null,
  no integer not null,
  action text not null default '',
  pic1 text not null default '-',
  pic2 text not null default '-',
  status text not null default 'Next Step',
  note text not null default '',
  priority text not null default '-',
  due date,
  tag_pic boolean not null default false,
  task_key uuid default gen_random_uuid(),
  updated_at timestamptz not null default now()
);

create index if not exists items_week_id_idx on public.items (week_id);
create index if not exists items_task_key_idx on public.items (task_key);

alter table public.weeks enable row level security;
alter table public.items enable row level security;

drop policy if exists "public read weeks" on public.weeks;
drop policy if exists "public write weeks" on public.weeks;
drop policy if exists "public update weeks" on public.weeks;
drop policy if exists "public delete weeks" on public.weeks;

drop policy if exists "authenticated read weeks" on public.weeks;
drop policy if exists "authenticated write weeks" on public.weeks;
drop policy if exists "authenticated update weeks" on public.weeks;
drop policy if exists "authenticated delete weeks" on public.weeks;

drop policy if exists "public read items" on public.items;
drop policy if exists "public write items" on public.items;
drop policy if exists "public update items" on public.items;
drop policy if exists "public delete items" on public.items;

drop policy if exists "authenticated read items" on public.items;
drop policy if exists "authenticated write items" on public.items;
drop policy if exists "authenticated update items" on public.items;
drop policy if exists "authenticated delete items" on public.items;

create policy "public read weeks" on public.weeks for select using (true);
create policy "public write weeks" on public.weeks for insert with check (true);
create policy "public update weeks" on public.weeks for update using (true);
create policy "public delete weeks" on public.weeks for delete using (true);

create policy "public read items" on public.items for select using (true);
create policy "public write items" on public.items for insert with check (true);
create policy "public update items" on public.items for update using (true);
create policy "public delete items" on public.items for delete using (true);

-- Enable Realtime so every open browser tab sees edits from teammates live.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'weeks') then
    alter publication supabase_realtime add table public.weeks;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'items') then
    alter publication supabase_realtime add table public.items;
  end if;
end $$;

-- Seed data matching the two weeks already in qaqc_meeting_tracker_v4.html.
insert into public.weeks (id, label, created_at) values
  ('wk1', '24 - 28 Aug 2026', now() - interval '7 days'),
  ('wk2', '31 Aug - 4 Sep 2026', now())
on conflict (id) do nothing;

insert into public.items (id, week_id, cat, no, action, pic1, pic2, status, note, priority, due, tag_pic) values
  ('i1','wk1','cat1',1,'Set Excel form matrix ให้โครงการ pilot กรอกรายชื่อ/ความเกี่ยวข้องเอกสารแต่ละ Doc Group','QAQC System Admin','-','Action Done','เสร็จแล้ว','-',null,false),
  ('i2','wk1','cat1',2,'Set Excel form การรันเลขเอกสารตาม Doc Group (KK4 และ LC3)','QAQC System Admin','-','Next Step','on progress','-',null,false),
  ('i3','wk1','cat1',3,'จัดการโครงการ KK4 ในระบบ Conzol ให้พร้อมเป็นตัวอย่าง (เคลียร์ Distribution Matrix / ติดตาม-อัพโหลดเอกสาร)','QAQC System Admin','-','Action Done','ต่อเนื่อง','-',null,false),
  ('i4','wk1','cat1',4,'ประสานงานกับ HR (นาเดียร์) ในการประกาศใช้ ConZol','Pavinee Talthip','-','Action Done','ต่อเนื่อง','-',null,false),
  ('i5','wk1','cat1',5,'พี่เอกแนะนำให้ Add PM แต่ละโครงการเข้ามาเห็นการใช้งาน Conzol ทุก Matrix โดยให้ PM Approve','-','-','Next Step','','-',null,false),
  ('i9','wk1','cat2',9,'Set เอกสาร Standard ร่วมกับทีม Execution KK4','Thanikorn Wangdee','Pavinee Talthip','Next Step','ต่อเนื่อง','-',null,false),
  ('i10','wk1','cat2',10,'กำหนด Flow ของ Format เอกสาร QA/QC','Thanikorn Wangdee','-','Next Step','ต่อเนื่อง','-',null,false),
  ('i14','wk1','cat3',14,'คุยกับทาง Conzol เรื่องรูปแบบการส่งข้อมูลที่ Link กับ Dashboard','Pitchayapa Yaklai','Pavinee Talthip','Next Step','ต่อเนื่อง','-',null,false),
  ('i15','wk1','cat3',15,'วางแผนจัดทำ Dashboard สำหรับการ Tracking เอกสารใน Conzol','Pitchayapa Yaklai','-','Next Step','ต่อเนื่อง','-',null,false),
  ('i16','wk1','cat3',16,'ศึกษาการอัพเดตงาน Daily ของ STSBPP และหาแนวทางพัฒนาด้วย AI','Pitchayapa Yaklai','-','Action Done','ข้อมูลในกลุ่มเป็น daily report ซึ่งจะมีการอัพลง ConZol เพื่อเก็บข้อมูลอยู่แล้ว','-',null,false),
  ('j1','wk2','cat1',1,'สร้างไฟล์รายชื่อและจำนวนเอกสารของ KK4 และประสานงานกับทีม Engineer','QAQC System Admin','-','Next Step','ต่อเนื่องจากสัปดาห์ก่อน','-',null,false),
  ('j2','wk2','cat1',2,'Focus เอกสาร Distribution Matrix - LC3 ให้พร้อมนำเข้าระบบพร้อมกันทั้ง Engineer/Execution','QAQC System Admin','-','Next Step','ต่อเนื่อง','-',null,false),
  ('j3','wk2','cat1',3,'ประสานงานกับพี่วิทย์เรื่องรูปแบบเอกสาร Execution ของ ผรม.','QAQC System Admin','-','Next Step','','-',null,false),
  ('j4','wk2','cat1',4,'ประสานงานกับพี่กานต์ + ทีม Execution + คณะจ้างเหมา สื่อสารกับ ผรม.(LC3)','QAQC System Admin','-','Next Step','','-',null,false),
  ('j5','wk2','cat1',5,'ประสานงานกับ HR (นาเดียร์) ทำ Roadmap สื่อสารเรื่องระบบ ConZol','Pavinee Talthip','-','Next Step','ต่อเนื่อง','-',null,false),
  ('j6','wk2','cat1',6,'เดินทางไป Site ทุ่งสง เพื่อติดตามการใช้งาน ConZol บริหารเอกสารโรงไฟฟ้า','Pavinee Talthip','Thanikorn Wangdee','Next Step','งานใหม่','-',null,false),
  ('j9','wk2','cat2',9,'ใช้เอกสารเดิมของ EPS ก่อน และนำเอกสารทุ่งสงมาปรับใช้ในส่วนที่ EPS ยังไม่มี','Tanawit Anantaphrut','-','Next Step','','-',null,false),
  ('j10','wk2','cat2',10,'จัดทำ ITP ของ EE โดยดูเอกสารทุ่งสงประกอบ และปรึกษาพี่นิสิต','Tanawit Anantaphrut','-','Next Step','','-',null,false),
  ('j11','wk2','cat2',11,'เดินทางไป Site ทุ่งสง หารือ Standard เอกสารต้นแบบ','Tanawit Anantaphrut','Pavinee Talthip','Next Step','','-',null,false),
  ('j14','wk2','cat3',14,'คุยกับ Conzol ต่อเนื่อง เรื่องรูปแบบการส่งข้อมูลที่ Link กับ Dashboard','Pitchayapa Yaklai','Pavinee Talthip','Next Step','ต่อเนื่อง','-',null,false),
  ('j15','wk2','cat3',15,'จัดทำ Mock up Doc Tracking Dashboard สำหรับงานฝั่ง Engineering และ Execution','Pitchayapa Yaklai','-','Next Step','','-',null,false),
  ('j16','wk2','cat3',16,'ทำ Project Charter รวบรวม Knowledge Base ส่งให้ทีม AI CBM','Pitchayapa Yaklai','-','Next Step','','-',null,false)
on conflict (id) do nothing;

-- Backfill: group existing rows by (cat, normalized action text) so copies of
-- the same task share one lineage key. Idempotent; no-op once all rows are keyed.
update public.items
set task_key = md5(cat || '::' || lower(btrim(action)))::uuid
where task_key is null;
