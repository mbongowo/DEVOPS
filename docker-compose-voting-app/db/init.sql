-- Runs once on first database init (mounted into /docker-entrypoint-initdb.d).
-- The worker also creates this table defensively, so the app is self-healing
-- even if the volume predates this script.
CREATE TABLE IF NOT EXISTS votes (
    id   VARCHAR(255) PRIMARY KEY,
    vote VARCHAR(255) NOT NULL
);
