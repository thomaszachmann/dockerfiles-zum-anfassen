# syntax=docker/dockerfile:1
# Runde 04 – kaputter Stand: baut, läuft, und hat etwas zu viel dabei
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY . .
RUN npm run build

FROM node:24-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app ./
RUN npm prune --omit=dev
USER node
EXPOSE 3000
CMD ["node", "server.js"]
