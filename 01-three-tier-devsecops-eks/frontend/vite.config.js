import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // Local dev proxy so the SPA can call the API on :3000.
    proxy: { '/api': 'http://localhost:3000' },
  },
});
