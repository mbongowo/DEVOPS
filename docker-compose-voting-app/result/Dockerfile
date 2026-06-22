FROM node:22-slim

WORKDIR /app

# Install deps against the lockfile-free manifest, production only.
COPY package.json .
RUN npm install --omit=dev && npm cache clean --force

COPY . .

USER node

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:80/healthz',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]
