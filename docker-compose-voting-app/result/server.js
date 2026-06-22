// Result service: reads vote tallies from Postgres and serves a live-updating page.
const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const OPTION_A = process.env.OPTION_A || 'Cats';
const OPTION_B = process.env.OPTION_B || 'Dogs';

const pool = new Pool({
  host: process.env.PGHOST || 'db',
  database: process.env.PGDATABASE || 'votes',
  user: process.env.PGUSER || 'postgres',
  password: process.env.PGPASSWORD || 'postgres',
  port: parseInt(process.env.PGPORT || '5432', 10),
});

const app = express();
app.use(express.static(path.join(__dirname, 'public')));

app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));

app.get('/api/results', async (_req, res) => {
  try {
    const { rows } = await pool.query(
      "SELECT vote, COUNT(*)::int AS count FROM votes GROUP BY vote"
    );
    const tally = { a: 0, b: 0 };
    for (const r of rows) {
      if (r.vote === 'a' || r.vote === 'b') tally[r.vote] = r.count;
    }
    res.json({ labels: { a: OPTION_A, b: OPTION_B }, votes: tally });
  } catch (err) {
    // Table may not exist until the worker has written its first vote.
    res.json({ labels: { a: OPTION_A, b: OPTION_B }, votes: { a: 0, b: 0 } });
  }
});

const port = parseInt(process.env.PORT || '80', 10);
app.listen(port, '0.0.0.0', () => console.log(`result listening on :${port}`));
