"""Worker: drain votes from Redis and persist the latest vote per voter to Postgres."""
import json
import os
import time

import psycopg2
import redis

REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
PG = dict(
    host=os.environ.get("PGHOST", "db"),
    dbname=os.environ.get("PGDATABASE", "votes"),
    user=os.environ.get("PGUSER", "postgres"),
    password=os.environ.get("PGPASSWORD", "postgres"),
)


def connect_redis():
    while True:
        try:
            r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)
            r.ping()
            print(f"connected to redis://{REDIS_HOST}:{REDIS_PORT}", flush=True)
            return r
        except redis.exceptions.RedisError as e:
            print(f"redis not ready ({e}); retrying...", flush=True)
            time.sleep(2)


def connect_pg():
    while True:
        try:
            conn = psycopg2.connect(**PG)
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(
                    "CREATE TABLE IF NOT EXISTS votes ("
                    "  id  VARCHAR(255) PRIMARY KEY,"
                    "  vote VARCHAR(255) NOT NULL"
                    ")"
                )
            print(f"connected to postgres {PG['host']}/{PG['dbname']}", flush=True)
            return conn
        except psycopg2.OperationalError as e:
            print(f"postgres not ready ({e}); retrying...", flush=True)
            time.sleep(2)


def main():
    r = connect_redis()
    conn = connect_pg()
    print("worker ready; waiting for votes", flush=True)

    while True:
        # Block up to 5s for the next vote so we periodically re-check liveness.
        item = r.blpop("votes", timeout=5)
        if item is None:
            continue
        _, raw = item
        try:
            data = json.loads(raw)
            voter_id, vote = data["voter_id"], data["vote"]
        except (ValueError, KeyError) as e:
            print(f"skipping malformed vote {raw!r}: {e}", flush=True)
            continue

        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO votes (id, vote) VALUES (%s, %s) "
                    "ON CONFLICT (id) DO UPDATE SET vote = EXCLUDED.vote",
                    (voter_id, vote),
                )
        except psycopg2.OperationalError:
            print("lost postgres connection; reconnecting", flush=True)
            conn = connect_pg()
            r.rpush("votes", raw)  # requeue the vote we couldn't write


if __name__ == "__main__":
    main()
