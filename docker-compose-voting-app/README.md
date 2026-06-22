# Docker Compose Voting App

A small but complete multi-service application orchestrated entirely with
**Docker Compose**. Users vote between two options; the result page updates live.
The point of the project is the orchestration, not the apps — it demonstrates the
Compose features you actually reach for in real stacks.

## Architecture

```
        ┌──────────┐      ┌─────────┐      ┌──────────┐      ┌──────────┐      ┌──────────┐
 vote → │  vote    │ ───▶ │  redis  │ ───▶ │  worker  │ ───▶ │   db     │ ◀─── │  result  │ ← browser
        │ (Flask)  │      │ (queue) │      │ (Python) │      │ (Postgres)│      │ (Node)   │
        └──────────┘      └─────────┘      └──────────┘      └──────────┘      └──────────┘
         front+back         back            back              back             front+back
```

| Service  | Tech            | Role                                                        |
|----------|-----------------|-------------------------------------------------------------|
| `vote`   | Python / Flask  | Web form; pushes each vote onto a Redis list                |
| `redis`  | redis:7-alpine  | In-memory queue buffering votes                             |
| `worker` | Python          | Pops votes from Redis, upserts the latest vote per voter    |
| `db`     | postgres:16     | Durable vote storage (named volume)                         |
| `result` | Node / Express  | Reads tallies from Postgres, live-updating results page     |

Two networks isolate tiers: only `vote` and `result` sit on `front-tier` (and are
port-published); `redis`, `worker`, and `db` are reachable only on `back-tier`.

## Compose features demonstrated

- **Build contexts** for the three first-party services + pinned official images.
- **Healthchecks** on every long-lived service (`redis-cli ping`, `pg_isready`,
  HTTP `/healthz` for `vote`/`result`).
- **`depends_on` with `condition: service_healthy`** so `worker`/`result` start only
  once their dependencies are actually ready — not just created.
- **Two isolated bridge networks** (front-tier / back-tier).
- **Named volume** (`db-data`) for Postgres durability across restarts.
- **Env interpolation** with defaults (`${VOTE_PORT:-8080}`) + a sample `.env`.
- **Resource limits** (`deploy.resources.limits`) on `vote` and `worker`.
- **Profiles** — an optional `seed` load generator that only runs on request.

## Run it

```bash
cp .env.example .env          # optional; sensible defaults are built in
docker compose up --build -d

# Vote:    http://localhost:8080
# Results: http://localhost:8081
```

Generate some traffic with the seed profile:

```bash
docker compose --profile seed run --rm seed   # pushes SEED_COUNT random votes
```

Tear down (and drop the database volume):

```bash
docker compose down -v
```

## Validation

Locally, the compose file is checked with `docker compose config`. In CI
(`.github/workflows/voting.yml`) GitHub's runner builds all images, brings the
full stack up, waits for every service to report **healthy**, casts votes through
the real HTTP endpoint, and asserts they propagate end-to-end
(`vote → redis → worker → postgres → result`) before tearing down.
