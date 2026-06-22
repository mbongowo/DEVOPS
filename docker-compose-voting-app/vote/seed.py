"""Optional load generator: push a batch of random votes onto Redis.

Enabled via the compose `seed` profile: `docker compose --profile seed up seed`.
"""
import json
import os
import random
import time

import redis

REDIS_HOST = os.environ.get("REDIS_HOST", "redis")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
OPTION_A = os.environ.get("OPTION_A", "a")
OPTION_B = os.environ.get("OPTION_B", "b")
COUNT = int(os.environ.get("SEED_COUNT", "100"))

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0)
for i in range(COUNT):
    vote = random.choice(["a", "b"])
    r.rpush("votes", json.dumps({"voter_id": f"seed-{i}", "vote": vote}))
    time.sleep(0.01)

print(f"seeded {COUNT} votes to redis://{REDIS_HOST}:{REDIS_PORT}")
