# Testing Checklist

What to verify in the browser after running the app — locally or after
deploying to EC2. Each check maps to a specific piece of the stack, so if
something fails, you'll know exactly which service to look at.

---

## 1. Local (`npm run dev`, both terminals)

| # | Check | URL / Action | Confirms |
|---|---|---|---|
| 1 | Backend is alive | `http://localhost:3001/health` → `{"ok":true}` | Backend process started, port bound correctly |
| 2 | Frontend loads | `http://localhost:5173` | Vite dev server running, no build errors |
| 3 | Sign up / log in | Click sign in, complete Clerk flow | `CLERK_PUBLISHABLE_KEY` / `CLERK_SECRET_KEY` correct |
| 4 | User synced to DB | Neon SQL Editor → `SELECT * FROM users;` shows your row | Clerk webhook (via ngrok) + `CLERK_WEBHOOK_SECRET` working |
| 5 | Catalog loads | Click "Shop" | `DATABASE_URL` (Neon) + Drizzle queries working |
| 6 | Product images load | Open any product | `IMAGEKIT_URL_ENDPOINT` (frontend) correct |
| 7 | Cart works | Add/remove items, quantities update | Frontend state only, no external service |
| 8 | Checkout opens | Cart → "Checkout securely" → real Polar page loads | `POLAR_ACCESS_TOKEN` + `POLAR_CHECKOUT_PRODUCT_ID` correct |
| 9 | Video calling | Order → video tab (requires a **paid** order) | `STREAM_API_KEY` / `STREAM_API_SECRET` correct |
| 10 | Admin pages | Only if your `role` is set to `admin` in DB | Role-based access control working |

**Note:** checks 8 and 9 require external webhooks (Polar, Clerk) reaching
your machine, which only works while `ngrok` is running and pointed at the
current tunnel URL registered in each dashboard.

---

## 2. Production (EC2 via docker-compose)

Replace `<EC2_IP>` with your instance's public IP (e.g. `52.90.98.108`).

| # | Check | URL / Action | Confirms |
|---|---|---|---|
| 1 | Backend is alive | `http://<EC2_IP>:3001/health` → `{"ok":true}` | Backend container running, port 3001 open in security group |
| 2 | Frontend loads | `http://<EC2_IP>` | Nginx container running, port 80 open in security group |
| 3 | Sign up / log in | Complete Clerk flow | `VITE_CLERK_PUBLISHABLE_KEY` baked correctly into frontend image |
| 4 | API calls hit the right host | DevTools → Network tab → requests go to `<EC2_IP>:3001`, not `localhost` | `VITE_API_URL` was set correctly at **build time** (GitHub Variable) before this image was built |
| 5 | Catalog + images load | Browse products | Same Neon DB + ImageKit as local — should already show existing data |
| 6 | Checkout opens | Cart → checkout | `POLAR_ACCESS_TOKEN` present in `backend.env` on the server |
| 7 | Containers healthy | SSH in → `docker ps` shows both `Up` | Compose file + `backend.env` are valid |
| 8 | No container errors | `docker logs pern-backend --tail 50` / `docker logs pern-frontend --tail 50` | No crash loops, DB connection errors, etc. |

**Known gap:** Clerk and Polar webhooks are still pointed at your old local
`ngrok` tunnel. New sign-ups on the EC2-deployed app will **not** auto-sync
to the database, and Polar order-paid events won't be received, until both
webhook endpoints are updated to `http://<EC2_IP>:3001/webhooks/clerk` and
the Polar equivalent.

---

## 3. Quick reference — what breaks if a service is misconfigured

| Symptom in browser | Likely cause |
|---|---|
| Blank page / connection refused | Frontend container not running, or port 80 blocked in security group |
| Products page empty | `DATABASE_URL` wrong, or `db:seed` never run against this DB |
| Broken product images | `IMAGEKIT_URL_ENDPOINT` wrong or missing on frontend |
| "Account not synced yet" (503) | Clerk webhook not reaching this environment |
| Checkout stuck on "Opening checkout..." | `POLAR_ACCESS_TOKEN` missing/invalid, or `POLAR_CHECKOUT_PRODUCT_ID` wrong |
| "Payments are not configured" | `POLAR_ACCESS_TOKEN` not set in this environment's env file |
| Video call fails to connect | `STREAM_API_KEY` / `STREAM_API_SECRET` wrong |
| Order must be paid before video | Expected — no webhook has marked any order as `paid` yet |
