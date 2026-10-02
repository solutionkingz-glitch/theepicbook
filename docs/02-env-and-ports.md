# EpicBook: environment variables, ports and persistence

## Components
- Frontend: static assets (CSS, JS, images) served by Nginx. Internal port 80.
- Backend: Node.js 22, Express + Handlebars + Sequelize. Start: npm start (node server.js). Internal port 8080.
- Database: MySQL 8.4, database name bookstore. Internal port 3306.
- Reverse proxy: Nginx. The only public entry point, host port 80.

## Environment variable names (names only)
Read by the original code:
- PORT, NODE_ENV, JAWSDB_URL (only when NODE_ENV=production)
Added for this deployment (backend, replaces hard-coded config.json values):
- DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
Read by the MySQL container:
- MYSQL_ROOT_PASSWORD, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD

## Ports
- 80   reverse-proxy: PUBLIC (the only published port)
- 80   frontend: private (front-tier)
- 8080 backend: private (front-tier and back-tier)
- 3306 database: private (back-tier, internal network)

## Routes
- Pages: GET /, GET /cart, GET /gallery, POST /category/:categoryName
- API prefix: /api/cart (POST, GET) and /api/cart/delete (DELETE)
- Static assets: /assets/
- Browser code uses relative URLs, so same-origin routing needs no CORS.

## Persistent data
- MySQL data directory: /var/lib/mysql, mounted from the named volume db_data
- Init files (first start only): db/BuyTheBook_Schema.sql, db/author_seed.sql, db/books_seed.sql

## Health checks
- Backend: GET /health (added in Task 3), 200 only when the database answers
- Database: mysqladmin ping
- Frontend and proxy: HTTP request to Nginx
