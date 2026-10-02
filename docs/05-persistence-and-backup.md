# Persistence, backup and restore

## What data is backed up
The complete `bookstore` MySQL database: the Author, Book, Cart, Cartbook and Checkout tables, plus routines and triggers if any exist. Application code and container images are rebuilt from Git and are not part of the backup.

## Persistence
MySQL stores its data in `/var/lib/mysql`, which is mounted from the named Docker volume `db_data`. The volume survives `docker compose down` and container recreation. It is deleted only by `docker compose down -v` or `docker volume rm`, which must not be used before all evidence is complete.

## Backup method
Logical backup with `mysqldump --single-transaction --routines --triggers`, run inside the database container. The root credential is read from the container's own environment, so no password is typed or logged. The output file is created with permissions 600.

## Backup location
`backups/` on the VM host, outside the database container and outside the volume. The directory is listed in `.gitignore`, so backup files never reach source control. File names contain a timestamp, for example `epicbook_bookstore_YYYYMMDD_HHMMSS.sql`.

## Schedule recommendation
Daily at 02:00 server time with cron, plus an extra backup before every deployment or schema change. After each run, check that the file is not empty and ends with a "Dump completed" line.

## Retention recommendation
Keep 14 daily backups and 8 weekly backups on the host, and copy backups to encrypted off-host storage such as an S3 bucket, so a lost VM does not mean lost data. Test a restore at least monthly.

## Restore procedure
1. Pick the backup file to restore and confirm its size and timestamp.
2. Stop the backend: `docker compose stop backend`.
3. Load the file into the database container: `docker compose exec -T database sh -c 'mysql -u root -p"$MYSQL_ROOT_PASSWORD" bookstore' < <backup-file>`.
4. Start the backend: `docker compose start backend`.
5. Verify the data and check `/health` through the reverse proxy.
The named volume is never deleted during a restore.

## Result of the manual test
1. A test record ("Backup Drill Test Book") was added and the book count was noted.
2. A backup was created in `backups/` and the record was found inside it.
3. Only that one record was deleted, and its absence was verified.
4. The backup was restored; the record and the original book count came back.
5. `docker compose down` followed by `docker compose up -d --wait` was run without `-v`; the same data was still present.
