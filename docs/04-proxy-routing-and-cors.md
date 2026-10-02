# Reverse proxy routing and CORS

## Selected reverse proxy
Nginx (nginx:stable-alpine). Traefik is not used. Configuration: proxy/nginx.conf, mounted read-only into the container.

## Routing rules (Docker service names, no IP addresses)
- /assets/*  -> frontend:80   (static CSS, JS and images)
- /health    -> backend:8080  (health endpoint)
- /api/*     -> backend:8080  (cart API)
- /          -> backend:8080  (server-rendered pages: /, /cart, /gallery, /category/*)

## Public exposure
- Only the reverse-proxy service publishes a host port: 80.
- Frontend (80), backend (8080) and MySQL (3306) are not published.
- The browser reaches everything through http://<VM_PUBLIC_IP>.

## CORS
CORS was NOT required. The browser loads pages, assets and API responses from the same origin (http://<VM_PUBLIC_IP>, port 80). The application's JavaScript calls relative URLs such as /api/cart, so no cross-origin request is made. No Access-Control-Allow-Origin header is configured, and wildcard CORS is never used.

## Verification
- Home page, /api/cart, a static asset and /health all return HTTP 200 through the proxy.
- The browser console shows no CORS errors.
