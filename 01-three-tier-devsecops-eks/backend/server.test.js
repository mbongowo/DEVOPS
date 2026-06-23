const request = require('supertest');
const app = require('./server');

describe('todos API', () => {
  it('health is ok', async () => {
    const r = await request(app).get('/healthz');
    expect(r.status).toBe(200);
    expect(r.body.status).toBe('ok');
  });

  it('creates, lists and deletes a todo', async () => {
    const created = await request(app).post('/api/todos').send({ title: 'buy milk' });
    expect(created.status).toBe(201);
    const id = created.body._id;

    const listed = await request(app).get('/api/todos');
    expect(listed.status).toBe(200);
    expect(listed.body.some((t) => t._id === id)).toBe(true);

    const del = await request(app).delete(`/api/todos/${id}`);
    expect(del.status).toBe(204);
  });

  it('rejects an empty title', async () => {
    const r = await request(app).post('/api/todos').send({ title: '   ' });
    expect(r.status).toBe(400);
  });

  it('exposes prometheus metrics', async () => {
    const r = await request(app).get('/metrics');
    expect(r.status).toBe(200);
    expect(r.text).toContain('api_http_requests_total');
  });
});
