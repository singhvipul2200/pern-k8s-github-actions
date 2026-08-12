# Standalone backend image — Express API only (no frontend files).
# Build from the backend/ folder: docker build -t <you>/pern-backend:latest ./backend

# --- Stage 1: compile TypeScript -> JavaScript ---
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --no-audit --no-fund
COPY . .
RUN npm run build
# produces ./dist (see backend/tsconfig.json outDir)

# --- Stage 2: runtime image (prod deps only) ---
FROM node:22-bookworm-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force

COPY --from=build /app/dist ./dist
COPY --from=build /app/scripts ./scripts
COPY --from=build /app/drizzle.config.ts ./drizzle.config.ts

EXPOSE 3001
USER node

CMD ["node", "--import", "./dist/instrument.js", "dist/index.js"]
