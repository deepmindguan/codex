---
name: jizhang-rebuild
description: Use this skill when restoring, rebuilding, redeploying, migrating, or repairing the personal Jizhang accounting PWA, including its React frontend, Fastify SQLite sync API, Nginx deployment, iPhone PWA behavior, cloud data, Excel export/reporting, categories, record editing, note suggestions, and teal statistics page.
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

## Latest Product Baseline

Preserve these features when repairing or rebuilding:

- PWA installable on iPhone via Safari "Add to Home Screen".
- Local-first IndexedDB storage with cloud sync.
- Server stores records, categories, accounts in SQLite.
- Expanded categories with icons.
- Record creation, record list, historical record editing, soft deletion.
- Note suggestions under the note box, based on category-specific history frequency plus defaults.
- Teal statistics page with income/expense toggle, week/month/year periods, trend line, total/average, and category ranking bars.
- Export Excel and JSON backup/restore from settings.
- Service worker should use network-first navigation behavior and a bumped cache name when changing frontend assets.

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
- Stats: switch expense/income and week/month/year.
- Settings: run sync if credentials are configured.

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

## Safe Repair Rules

- Do not wipe `/var/lib/jizhang-api` unless the user explicitly asks and a backup exists.
- Do not replace `/etc/jizhang-api.env` without preserving or intentionally rotating `SYNC_KEY`.
- When changing sync schema, update both `api/src/schema.js` and `api/src/db.js`, then ensure frontend sync types still match.
- When changing frontend assets or service worker behavior, bump the cache name in `web/public/sw.js`.
- Prefer current scripts over hand-deploying: `web/npm run deploy` and `scripts/deploy-api.sh`.
- After deployment, always run remote health checks and tell the user whether sync/API/frontend are OK.
