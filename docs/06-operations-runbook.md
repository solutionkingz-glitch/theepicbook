# EpicBook operations runbook

Project folder: ~/theepicbook. Run every command from there.
Warning: never use `docker compose down -v` on a live system. It deletes the db_data volume and all stored data.

## 1. Normal startup
- First start or after code changes: `docker compose up -d --build`
- Start without rebuilding: `docker compose up -d --wait` (returns when all services are healthy)
- Enforced order: database healthy, then backend healthy, then frontend and reverse-proxy.

## 2. Normal shutdown (data kept)
- `docker compose down` removes containers and networks only.
- The db_data volume and the host folders backups/ and logs/ are kept.

## 3. Health and logs
- Status: `docker compose ps`
- End-to-end check: `curl -i http://localhost/health` (200 means proxy, backend and database all answer; 503 means the database is unreachable; 502 means the backend is down)
- Backend logs (stdout): `docker compose logs backend --tail=50` (add `-f` to follow)
- Database logs: `docker compose logs database --tail=50`
- Proxy logs on the host: logs/proxy/access.log (JSON) and logs/proxy/error.log

## 4. Safe restarts (one service at a time, verify health after each)
- Proxy: `docker compose restart reverse-proxy`
- Frontend: `docker compose restart frontend`
- Backend: `docker compose restart backend`
- Database: `docker compose restart database` (the backend may restart too; verify afterwards)
- Nginx resolves service names at startup. If the proxy returns 502 after another service was recreated, restart the proxy.

## 5. Backup
- Run: `mkdir -p backups` then
  `docker compose exec -T database sh -c 'mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --triggers --no-tablespaces bookstore' > backups/epicbook_bookstore_$(date +%Y%m%d_%H%M%S).sql`
- Check that the file is not empty and ends with a "Dump completed" line.
- Recommended: daily at 02:00 via cron, plus before every deployment. Keep 14 daily and 8 weekly copies, and copy them off the host.

## 6. Restore
1. Choose the backup file and confirm its timestamp and size.
2. `docker compose stop backend`
3. `docker compose exec -T database sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" bookstore' < backups/<file>.sql`
4. `docker compose start backend`
5. Verify the data and `curl -i http://localhost/health`. The volume is never deleted.

## 7. Secret rotation (high level)
- Generate a new random value (for example `openssl rand -hex 16`).
- MYSQL_* variables only apply when the volume is first initialized, so changing .env alone does not change an existing database. Change the password inside MySQL first (`ALTER USER`), then update .env, then recreate the affected containers (`docker compose up -d`).
- Keep .env out of Git and out of screenshots. Rotate the SSH key pair through Terraform. After rotating, run the post-incident checklist.

## 8. Post-incident verification checklist
- [ ] `docker compose ps` shows all four services healthy
- [ ] `curl -i http://localhost/health` returns 200
- [ ] Home page, one API call and one static asset load through http://<VM_PUBLIC_IP>
- [ ] A known record is still present in the database
- [ ] Backend and proxy logs show no repeating errors
- [ ] Only port 80 is published (`docker ps` and security group)
- [ ] A fresh backup was taken and the incident is written up
