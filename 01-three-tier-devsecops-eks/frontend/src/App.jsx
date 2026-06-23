import React, { useEffect, useState } from 'react';

const API = '/api/todos';

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState('');

  const load = () =>
    fetch(API)
      .then((r) => r.json())
      .then(setTodos)
      .catch(() => setTodos([]));

  useEffect(() => {
    load();
  }, []);

  const add = async (e) => {
    e.preventDefault();
    if (!title.trim()) return;
    await fetch(API, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title }),
    });
    setTitle('');
    load();
  };

  const remove = async (id) => {
    await fetch(`${API}/${id}`, { method: 'DELETE' });
    load();
  };

  return (
    <main style={{ fontFamily: 'system-ui', maxWidth: 480, margin: '6vh auto', padding: '0 1rem' }}>
      <h1>📝 Three-Tier Todo</h1>
      <form onSubmit={add} style={{ display: 'flex', gap: '.5rem' }}>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Add a task…"
          style={{ flex: 1, padding: '.5rem' }}
        />
        <button>Add</button>
      </form>
      <ul>
        {todos.map((t) => (
          <li key={t._id}>
            {t.title} <button onClick={() => remove(t._id)}>✕</button>
          </li>
        ))}
      </ul>
      <p style={{ color: '#888', fontSize: '.8rem' }}>React → Node/Express → MongoDB</p>
    </main>
  );
}
