# syntax=docker/dockerfile:1
# check=error=true
# notes-web – Stand Ende Tag 13
# in Produktion: @sha256:… pinnen, siehe Tag 8
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
# Tag 13: .npmrc (mit Registry-Token) nur für diesen RUN, optional (required=false)
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
COPY . .
RUN npm run build

FROM node:24-alpine AS prod
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci --omit=dev
COPY server.js ./
COPY public/ ./public/
COPY --from=build /app/dist/ ./dist/
USER node
EXPOSE 3000
CMD ["node", "server.js"]
