---
name: jizhang-rebuild
description: Use this skill when restoring, rebuilding, redeploying, migrating, or repairing the personal Jizhang accounting PWA, including its React frontend, Fastify SQLite sync API, Nginx deployment, iPhone PWA behavior, cloud data, historical CSV imports, Excel export/reporting, categories, record editing, note suggestions, and teal statistics page.
---

# Jizhang Rebuild

Use this for the user's personal accounting app when they ask to recover from breakage, rebuild on a new machine/server, migrate servers, verify the latest deployment, or continue development without losing the known project shape.

## Current Shape

- Local project root: `/Users/soros/Downloads/project/jizhang`
- Frontend: `web`, React 18 + TypeScript + Vite + Dexie + Recharts + lucide-react
- Backend: `api`, Fastify + better-sqlite3 + zod
- Current server: `root@118.145.224.120`
- Public site: `http://118.145.224.120/`
- Frontend deploy target: `/var/www/jizhang`
- API deploy target: `/opt/jizhang-api`
- API service: `jizhang-api`
- API listen address: `127.0.0.1:3001`
- Nginx proxies `/api/` to `127.0.0.1:3001`
- SQLite data: `/var/lib/jizhang-api/jizhang.sqlite`
- API env file: `/etc/jizhang-api.env`
- Sync key: do not hardcode; read from `/etc/jizhang-api.env` or generate a new one during rebuild.
- Sync payload size: Fastify `bodyLimit` should be `50 * 1024 * 1024`; Nginx site should include `client_max_body_size 50m;`.
- Current cloud baseline as of 2026-06-07: 4886 records, 41 categories, 5 accounts.
- Current data range: 2022-02 through 2026-06.

## Latest Product Baseline

Preserve these features when repairing or rebuilding:

- PWA installable on iPhone via Safari "Add to Home Screen".
- Local-first IndexedDB storage with cloud sync.
- Server stores records, categories, accounts in SQLite.
- Expanded categories with icons.
- Record creation, record list, historical record editing, soft deletion.
- Add-record page uses a category-first flow: the bottom amount/note/keypad sheet is hidden initially and only slides up after the user taps a category. It includes note suggestions, account/date controls, custom numeric keypad, close button, and `完成`.
- Note suggestions under the note box, based on category-specific history frequency plus defaults.
- Teal statistics page with income/expense toggle, week/month/year periods, trend line, total/average, and category ranking bars.
- Statistics time selector is data-driven: week/month/year options are generated from actual records, so old months like 2022-02 and 2025/2026 imports remain selectable by horizontal scrolling.
- Statistics page must not horizontally overflow in iPhone Home Screen PWA mode; keep page width within viewport and constrain ranking amount columns.
- Export Excel and JSON backup/restore from settings.
- Settings category/account management is low-risk by default: show clean tags only. Deletion is available only after tapping `编辑`, then a small delete control appears per tag, and deletion still requires confirmation. Do not make ordinary tag taps delete anything.
- Service worker should use network-first navigation behavior and a bumped cache name when changing frontend assets.
- iPhone Safari and "Add to Home Screen" PWA use separate local storage. If one syncs and the other does not, preserve the data-bearing copy, fix sync, then run `立即同步` in that copy first.

## Imported Historical Data

Historical Shark Accounting CSV exports have already been imported into the cloud database:

- `鲨鱼记账明细(4).csv`: 2022-02-19 through 2022-12-31.
- `鲨鱼记账明细(3).csv`: 2023-01-01 through 2023-12-31.
- `鲨鱼记账明细(2).csv`: 2024-01-01 through 2024-12-31.
- `鲨鱼记账明细(1).csv`: 2025-01-01 through 2025-12-31.
- `鲨鱼记账明细.csv`: 2026-01-01 through 2026-05-31.
- Manual screenshot imports covered 2026-06-01 through 2026-06-04.

CSV import rules used so far:

- Source encoding is UTF-16 little-endian and delimiter is tab.
- Required columns: `日期`, `收支类型`, `类别`, `账户`, `金额`, `备注`.
- Map `支出` to `expense`, `收入` to `income`.
- Map source account `未关联` to local account `现金` (`acc-cash`).
- Match categories by current category name and record type; stop and report if a category is missing.
- Use stable import IDs so reruns overwrite/skip rather than duplicate.
- Check exact duplicates against server by date, type, amount, category, and note before import.
- Back up SQLite before any import.

## Local Verification

From the project root:

```bash
cd /Users/soros/Downloads/project/jizhang/web
npm run lint
npm run build
npm run preview -- --host 127.0.0.1 --port 4173
```

Use `scripts/local-health.sh` in this skill for a quick local check:

```bash
/Users/soros/.codex/skills/jizhang-rebuild/scripts/local-health.sh /Users/soros/Downloads/project/jizhang
```

After significant frontend changes, verify a mobile viewport. Key flows:

- Add record: enter amount, choose category, click a note suggestion, save.
- Records: open an old record, edit amount/category/note, save.
- Stats: switch expense/income and week/month/year; horizontally scroll old months/years; verify 2022-2026 data appears after sync.
- In iPhone Home Screen PWA mode, verify statistics ranking amounts stay inside the viewport. A good browser check is `document.documentElement.scrollWidth === document.documentElement.clientWidth`.
- Settings: run sync if credentials are configured.
- Settings management: verify plain category/account tags do not delete; tap `编辑`, then delete button appears and confirm dialog gates deletion.

## Deploy Existing Server

Frontend:

```bash
cd /Users/soros/Downloads/project/jizhang/web
npm run deploy
```

API:

```bash
cd /Users/soros/Downloads/project/jizhang
./scripts/deploy-api.sh
```

Remote health check:

```bash
/Users/soros/.codex/skills/jizhang-rebuild/scripts/remote-health.sh 118.145.224.120
```

Expected checks:

- `curl http://HOST/api/health` returns `{"ok":true,...}`.
- `curl http://HOST/` references current `/assets/index-*.js` and CSS.
- `systemctl status jizhang-api` is active.
- `nginx -t` passes.

## Rebuild On New Server

Assume Ubuntu/Debian with root SSH access.

1. Install base packages:

```bash
apt update
apt install -y nginx curl ca-certificates build-essential python3 make g++
```

2. Install Node.js 20 LTS or compatible Node 18+.

3. Create API data/env:

```bash
mkdir -p /var/lib/jizhang-api
chown -R root:root /var/lib/jizhang-api
openssl rand -hex 24
```

Create `/etc/jizhang-api.env`:

```text
HOST=127.0.0.1
PORT=3001
DB_PATH=/var/lib/jizhang-api/jizhang.sqlite
SYNC_KEY=<new-or-restored-sync-key>
```

4. Create systemd service `/etc/systemd/system/jizhang-api.service`:

```ini
[Unit]
Description=Jizhang API
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/jizhang-api
EnvironmentFile=/etc/jizhang-api.env
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

5. Configure Nginx:

```nginx
server {
    listen 80;
    server_name _;
    client_max_body_size 50m;

    root /var/www/jizhang;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /sw.js {
        add_header Cache-Control "no-cache";
        try_files $uri =404;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

6. Deploy API and frontend using environment overrides:

```bash
cd /Users/soros/Downloads/project/jizhang
REMOTE_HOST=<new-host> REMOTE_USER=root ./scripts/deploy-api.sh
cd web
REMOTE_HOST=<new-host> REMOTE_USER=root npm run deploy
```

7. Start/enable:

```bash
systemctl daemon-reload
systemctl enable --now jizhang-api
nginx -t && systemctl reload nginx
```

8. Update iPhone app settings:

- Server address: `http://<new-host>`
- Sync key: value in `/etc/jizhang-api.env`
- Run Settings -> Immediately Sync.

## Data Recovery And Migration

Before risky changes, back up the remote SQLite database:

```bash
ssh root@118.145.224.120 "mkdir -p /root/jizhang-backups && sqlite3 /var/lib/jizhang-api/jizhang.sqlite '.backup /root/jizhang-backups/jizhang-$(date +%F-%H%M%S).sqlite'"
```

If `sqlite3` is unavailable, stop service and copy the DB plus WAL/SHM files:

```bash
ssh root@HOST "systemctl stop jizhang-api && cp -a /var/lib/jizhang-api/jizhang.sqlite* /root/ && systemctl start jizhang-api"
```

To move data to a new server, copy `/var/lib/jizhang-api/jizhang.sqlite*` to the new server while the API is stopped, then start the API and run `/api/health`.

## Sync Failure Recovery

If iPhone shows `同步失败：413`:

1. Treat this as payload too large, usually because the Home Screen PWA has more local data than Safari.
2. Do not delete the Home Screen icon or clear Safari/PWA data.
3. Ensure API has `bodyLimit: 50 * 1024 * 1024` in `api/src/server.js`, deploy API, and restart `jizhang-api`.
4. Ensure Nginx site has `client_max_body_size 50m;`, then `nginx -t && systemctl reload nginx`.
5. Verify with a large harmless payload against both `http://127.0.0.1:3001/api/sync` and `http://127.0.0.1/api/sync`; both should return `200`, not `413`.
6. Ask the user to run `立即同步` first in the data-bearing PWA, then sync Safari afterward to pull the cloud copy.

If categories disappear after accidental taps in Settings:

1. Back up remote SQLite first.
2. Restore category visibility on the server and make server timestamps newer than the mistaken local archived state:

```bash
ssh root@118.145.224.120 'cp /var/lib/jizhang-api/jizhang.sqlite /var/lib/jizhang-api/jizhang.before-category-restore.$(date +%Y%m%d%H%M%S).sqlite && node --input-type=module <<"NODE"
import Database from "better-sqlite3";
const db = new Database("/var/lib/jizhang-api/jizhang.sqlite");
db.prepare("UPDATE categories SET archived = 0, deleted_at = NULL, updated_at = ?").run(new Date().toISOString());
NODE
systemctl restart jizhang-api'
```

3. Then have the user run `立即同步` in the affected iPhone PWA so the restored cloud categories overwrite local mistaken archives.

## CSV Import Procedure

When importing another Shark Accounting CSV:

1. Read as UTF-16 text and parse as tab-delimited CSV.
2. Validate the exact headers: `日期`, `收支类型`, `类别`, `账户`, `金额`, `备注`.
3. Validate every date (`YYYY年MM月DD日`) and every amount as a decimal.
4. Fetch `/api/sync` with the sync key and build category/account maps from live server data.
5. Map every row to a `MoneyRecord`; if any category is missing, stop before writing.
6. Compute exact duplicate keys against existing server records and report the count.
7. Back up `/var/lib/jizhang-api/jizhang.sqlite*`.
8. Import via `/api/sync`. If Nginx returns `413 Request Entity Too Large`, split into batches of about 400 records.
9. Fetch `/api/sync` again and verify total imported count, date range, month/year totals, category distribution, and `/api/health`.

Never import by editing SQLite directly unless the API is unavailable and the user explicitly approves a recovery-mode path.

## Safe Repair Rules

- Do not wipe `/var/lib/jizhang-api` unless the user explicitly asks and a backup exists.
- Do not replace `/etc/jizhang-api.env` without preserving or intentionally rotating `SYNC_KEY`.
- When changing sync schema, update both `api/src/schema.js` and `api/src/db.js`, then ensure frontend sync types still match.
- When changing frontend assets or service worker behavior, bump the cache name in `web/public/sw.js`.
- Prefer current scripts over hand-deploying: `web/npm run deploy` and `scripts/deploy-api.sh`.
- After deployment, always run remote health checks and tell the user whether sync/API/frontend are OK.
- For statistics layout, keep `html`, `body`, `#root`, `.app-shell`, and `.stats-page` protected against horizontal overflow; ranking amount text must not force the row wider than the viewport.
