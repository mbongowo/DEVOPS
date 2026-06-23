# --- build stage ---
FROM node:20-slim AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install && npm cache clean --force
COPY . .
RUN npm run build

# --- runtime stage ---
FROM nginxinc/nginx-unprivileged:1.27-alpine
# Patch base OS packages (openssl, etc.) to clear fixable CRITICAL CVEs.
USER root
RUN apk upgrade --no-cache
USER nginx
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
