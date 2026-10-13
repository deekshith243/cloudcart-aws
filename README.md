# CloudCart

CloudCart is a production-style e-commerce and order management platform built for an AWS Developer interview.

## Phases 1 through 9

CloudCart now includes the React/Vite frontend, Express API, Prisma PostgreSQL schema, authentication, catalog management, cart/order workflows, Redis catalog caching, S3 product image boundaries, and SQS/SNS order-event boundaries. AWS services remain configuration-driven and unverified until deployed with real infrastructure.

See [docs/architecture.md](docs/architecture.md) and [docs/development.md](docs/development.md) for the current boundaries and commands.

## Local quick start

From PowerShell in the repository root:

```powershell
Copy-Item .env.example .env
npm install
npm --prefix frontend install
npm --prefix backend install
npm --prefix worker install
docker compose up -d postgres redis
npm --prefix backend run db:setup
```

## Docker Compose deployment

The complete Compose stack runs the frontend, backend, migration job, worker, PostgreSQL, and Redis:

```powershell
Copy-Item .env.example .env
# Replace POSTGRES_PASSWORD and JWT_SECRET with strong generated values.
docker compose up -d --build
docker compose ps
```

The frontend is published on `http://localhost:8080` by default. Nginx proxies `/api/*` and `/health` to the backend while preserving SPA fallback for other paths. PostgreSQL and Redis are private to the Compose network and are not published on the host.

The migration service waits for PostgreSQL health before running `prisma migrate deploy`; the backend waits for migration completion and Redis health. The worker starts after the backend is healthy. The worker is idle unless `AWS_REGION`, `AWS_SQS_ORDER_QUEUE_URL`, and `AWS_SNS_ORDER_TOPIC_ARN` are configured. Backend S3 image uploads also require `AWS_REGION` and `AWS_S3_BUCKET`. On EC2, prefer an instance IAM role over AWS access keys in `.env`.

For an EC2 deployment, install Docker and the Compose plugin, copy the repository and a populated `.env` file to the instance, then run `docker compose up -d --build`. Open only the frontend host port in the EC2 security group; do not expose ports 5432 or 6379.

To seed the local Compose database after migrations complete, set `SEED_ADMIN_PASSWORD` and `SEED_CUSTOMER_PASSWORD` in `.env`, then run the migration image manually:

```powershell
docker compose run --rm migration npx tsx prisma/seed.ts
```

The seed is idempotent for the fixed demo users, carts, categories, and products. `DATABASE_SSL=false` is used only for local Compose PostgreSQL; managed production databases retain SSL because the seed defaults to SSL unless explicitly disabled.

Start the frontend, API, and optional idle worker in separate terminals:

```powershell
npm run dev:frontend
npm run dev:backend
npm run dev:worker
```

The frontend is served by Vite, the API is at `http://localhost:4000`, and PostgreSQL/Redis are provided by Docker Compose. AWS S3/SQS/SNS are optional for local catalog, cart, and order flows; the worker reports that it is idle when SQS is not configured.

Run the repository checks with `npm run test`, `npm run build`, `npm run lint`, and `npm run format:check`.
