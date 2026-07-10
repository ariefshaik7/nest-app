# 1. Install Dependencies
FROM node:24-bookworm-slim AS base

FROM base AS deps
WORKDIR /app
# Install dependencies based on the preferred package manager
COPY package.json package-lock.json ./
RUN npm ci

# 2. Builder
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
RUN npm prune --omit=dev

# 3. Production Runner (Distroless)
FROM gcr.io/distroless/nodejs24-debian13 AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder --chown=65532:65532 /app/node_modules ./node_modules
COPY --from=builder --chown=65532:65532 /app/dist ./dist
USER 65532
EXPOSE 3000
CMD ["dist/main.js"]
