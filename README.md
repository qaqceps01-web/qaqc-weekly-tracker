# QA/QC Weekly Meeting Tracker

Single-file HTML app for the weekly QA/QC MOM meeting. No build step, no framework — `index.html` is the whole app, backed by a Supabase Postgres database so the team shares one live dataset instead of an Excel file.

**Live:** https://qaqc-weekly-tracker.vercel.app (also published to GitHub Pages)

## Deploying

Push to `main`. Two deployments update automatically:

- **Vercel** — the Vercel project is connected to this repo and redeploys within a minute.
- **GitHub Pages** — `.github/workflows/deploy-pages.yml` publishes the repo root.

If a change needs a database update (see [Database migrations](#database-migrations)), run the SQL in Supabase **before** pushing, otherwise the live app will fail to save.

## Setup (new Supabase project, one time)

1. Create a free project at [supabase.com](https://supabase.com/dashboard) (New project → pick a name/region → wait ~2 min for it to provision).
2. Open **SQL Editor** → paste the contents of `database/schema.sql` → Run. This creates the `weeks` and `items` tables (including `task_key`), seeds two example weeks, enables Realtime, and opens read/write access.
3. Open **Settings → API** and copy the **Project URL** and the **anon / publishable key**.
4. In `index.html`, near the top of the `<script>` block, set:
   ```js
   const SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
   const SUPABASE_ANON_KEY = 'sb_publishable_...';
   ```
5. Commit and push.

## Database migrations

Existing databases are upgraded with the scripts in `database/`. Each one is idempotent (safe to re-run). Take a backup first.

| Script | What it does |
|---|---|
| `migration_20261027_task_key.sql` | Adds `items.task_key` (links every weekly copy of the same task), backfills existing rows by category + wording, and **permanently deletes** unfinished copies of tasks that already have an Action Done copy. Required by any `index.html` that writes `task_key`. |

To check whether it has been applied, run `select task_key from items limit 1;` — an error saying the column does not exist means it has not.

## Backups

`tools/backup.ps1` downloads every row of `weeks` and `items` (read-only) into `backup/<timestamp>/` as JSON:

```powershell
powershell -ExecutionPolicy Bypass -File tools/backup.ps1
```

## What's included

- **Login gate** — only whitelisted `@scg.com` emails (the `WHITELIST` array in `index.html`) can open the app.
- Excel-style table: click a cell, type, blur to save. Columns: Action Item, PIC / PIC 2, Priority, Status, Note, Due Date.
- **Priority focus** — unfinished High-priority rows get a red marker so the team sees them during screen-share.
- **Weeks** — dropdown to switch weeks; "+ สัปดาห์ใหม่" creates a week and copies the **unfinished items of the previous week only**. Tasks deleted or reworded in the latest week therefore never come back from older weeks.
- **Done cleanup** — marking a task Action Done removes its other copies in every week (matched by `task_key`, so rewording does not break the link).
- **Filters** — my tasks, High only, not done / done, PIC, priority, keyword search, and a date range that shows tasks across weeks. Adding a task while filtered pre-fills the filtered PIC / priority and keeps the new row visible.
- **Excel export** (`.xlsx`, via SheetJS) of the current view.
- **Email MOM export** matching the team's template, with @PIC tags and Outlook-ready mailto links.
- **Realtime sync** — edits appear for everyone within a second or two (Supabase Realtime).

## Adding a team member

Edit these lists in `index.html`:

1. `ROSTER` — name in the PIC dropdown.
2. `PIC_EMAILS` — name → email (used for @PIC links in the email export).
3. `WHITELIST` — lowercase email allowed to log in.
4. `EMAIL_TO_PIC` — email → name (used by "งานของฉัน").
5. Optionally `EMAIL_TEMPLATE.to` / `.cc` if they should receive the MOM email.

## Data model

Two tables, see `database/schema.sql` for the full definition and RLS policies:

- `weeks (id, label, created_at)`
- `items (id, week_id, cat, no, action, pic1, pic2, status, note, priority, due, tag_pic, task_key, updated_at)`

`task_key` is shared by every weekly copy of one task: carried-forward copies inherit it, new tasks get a fresh UUID.

## Security note

The email login is a convenience gate in the browser, not real authentication: the anon key is in the page, and the database policies still allow anyone who has it to read and write. That matches the original "click and type during the meeting" workflow. If it stops being acceptable, add Supabase Auth and tighten the RLS policies in `database/schema.sql` to require an authenticated session.
