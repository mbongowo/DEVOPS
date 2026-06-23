// Three-tier demo API: a todo service backed by MongoDB (falls back to an
// in-memory store when MONGO_URL is unset, so unit tests need no database).
const express = require('express');
const client = require('prom-client');

const app = express();
app.use(express.json());

const register = new client.Registry();
client.collectDefaultMetrics({ register });
const httpRequests = new client.Counter({
  name: 'api_http_requests_total',
  help: 'HTTP requests',
  labelNames: ['method', 'route', 'code'],
  registers: [register],
});

// --- storage: Mongo if configured, else in-memory ---
let store;
async function getStore() {
  if (store) return store;
  if (process.env.MONGO_URL) {
    const { MongoClient } = require('mongodb');
    const mongo = await MongoClient.connect(process.env.MONGO_URL);
    const col = mongo.db('app').collection('todos');
    store = {
      list: () => col.find().toArray(),
      add: async (title) => {
        const r = await col.insertOne({ title, done: false });
        return { _id: r.insertedId, title, done: false };
      },
      remove: async (id) => {
        const { ObjectId } = require('mongodb');
        await col.deleteOne({ _id: new ObjectId(id) });
      },
    };
  } else {
    const mem = [];
    let seq = 1;
    store = {
      list: async () => mem,
      add: async (title) => {
        const t = { _id: String(seq++), title, done: false };
        mem.push(t);
        return t;
      },
      remove: async (id) => {
        const i = mem.findIndex((t) => t._id === id);
        if (i >= 0) mem.splice(i, 1);
      },
    };
  }
  return store;
}

app.get('/api/todos', async (_req, res) => {
  httpRequests.inc({ method: 'GET', route: '/api/todos', code: 200 });
  res.json(await (await getStore()).list());
});

app.post('/api/todos', async (req, res) => {
  const title = (req.body && req.body.title ? String(req.body.title) : '').trim();
  if (!title) {
    httpRequests.inc({ method: 'POST', route: '/api/todos', code: 400 });
    return res.status(400).json({ error: 'title required' });
  }
  const todo = await (await getStore()).add(title);
  httpRequests.inc({ method: 'POST', route: '/api/todos', code: 201 });
  res.status(201).json(todo);
});

app.delete('/api/todos/:id', async (req, res) => {
  await (await getStore()).remove(req.params.id);
  httpRequests.inc({ method: 'DELETE', route: '/api/todos/:id', code: 204 });
  res.status(204).end();
});

app.get('/healthz', (_req, res) => res.json({ status: 'ok' }));
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

if (require.main === module) {
  const port = parseInt(process.env.PORT || '3000', 10);
  app.listen(port, '0.0.0.0', () => console.log(`api on :${port}`));
}

module.exports = app;
