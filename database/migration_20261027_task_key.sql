-- Migration: task lineage via `task_key` + one-time ghost cleanup
-- Run ONCE in the Supabase SQL Editor, BEFORE deploying the updated index.html.
--
-- What it does:
--   1. Adds `task_key uuid` to public.items (all copies of the same logical
--      task share one key; carry-forward copies inherit it from the source row).
--   2. Backfills keys deterministically from (cat, normalized action text)
--      so existing copies of the same wording group together.
--   3. Deletes stale "ghost" copies: pending copies of a task that already has
--      an Action Done copy anywhere (fixed the duplicated rows seen in the
--      cross-week date-range view).
--
-- Idempotent: safe to re-run. Backup files: backup/20261027_151519 (JSON).

begin;

-- 1. Column + index -----------------------------------------------------------
alter table public.items add column if not exists task_key uuid;
create index if not exists items_task_key_idx on public.items (task_key);

-- 2. Backfill: one deterministic key per (cat, normalized action text) ---------
update public.items
set task_key = md5(cat || '::' || lower(btrim(action)))::uuid
where task_key is null;

-- Give future non-app inserts a fallback key of their own
alter table public.items alter column task_key set default gen_random_uuid();

-- 3. One-time ghost cleanup ----------------------------------------------------
-- A pending copy is redundant whenever the same task (task_key) has an
-- Action Done copy. Removes stale Next Step ghosts in earlier/later weeks,
-- and same-week duplicates arising from carry-forward races.
delete from public.items i
using public.items d
where d.status = 'Action Done'
  and i.status <> 'Action Done'
  and i.task_key = d.task_key
  and i.id <> d.id;

commit;

-- ----------------------------------------------------------------------------
-- Verification queries (run after the migration):
--
-- Pending copies that still have a done sibling (should return 0):
-- select count(*) from public.items i
-- where i.status <> 'Action Done'
--   and exists (
--     select 1 from public.items d
--     where d.task_key = i.task_key and d.status = 'Action Done'
--   );
--
-- Distinct task count vs row count (rows > tasks is expected while pending):
-- select count(*) as rows, count(distinct task_key) as tasks from public.items;
