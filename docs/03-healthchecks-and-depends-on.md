# Health checks and startup dependencies

## Health-check methods
- database: `mysqladmin ping -h 127.0.0.1` run as root inside the MySQL container (real network connection, checked every 10s, 40s start period)
- backend: Node.js `fetch` against `GET /health` on port 8080. The route runs `sequelize.authenticate()` and returns 200 only when the database answers, otherwise 503. The check uses Node itself, so no extra tools are installed in the image.
- frontend: `wget` request for a real static file (`/assets/css/style.css`) from the Nginx container
- reverse-proxy: `wget http://127.0.0.1/health` through Nginx, which proves the proxy is up AND can reach the backend

## Startup dependency order
1. database starts first and must be healthy
2. backend waits for database (`condition: service_healthy`), then syncs the schema and starts listening
3. frontend starts independently and must be healthy
4. reverse-proxy waits for BOTH frontend and backend to be healthy (`condition: service_healthy`)

Only the reverse-proxy publishes a host port (80). A container that has merely started is not treated as ready: every dependency uses `service_healthy`, not a plain `depends_on` list.

## Verification
- `docker compose ps` shows all four services healthy
- `curl -i http://<VM_PUBLIC_IP>/health` returns HTTP 200 through the reverse proxy
