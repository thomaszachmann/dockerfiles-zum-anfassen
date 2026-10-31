# syntax=docker/dockerfile:1
# notes-web, Stand Tag 6: bündeln im build-Stage, zur Laufzeit nur Prod-Abhängigkeiten
ARG NODE_VERSION=24

# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM node:${NODE_VERSION}-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM node:${NODE_VERSION}-alpine
LABEL org.opencontainers.image.title="notes-web" \
      org.opencontainers.image.description="Oberfläche und Proxy für notes-api" \
      org.opencontainers.image.source="https://example.com/docker-lab/notes"
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev
COPY server.js ./
COPY public ./public
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
STOPSIGNAL SIGTERM
ENTRYPOINT ["node", "server.js"]
