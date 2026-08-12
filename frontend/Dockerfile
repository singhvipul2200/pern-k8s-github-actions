# Standalone frontend image — static SPA served by Nginx.
# Build from the frontend/ folder: docker build -t <you>/pern-frontend:latest ./frontend

# --- Stage 1: build the static assets ---
FROM node:22-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --no-audit --no-fund
COPY . .

ARG VITE_CLERK_PUBLISHABLE_KEY
ARG VITE_API_URL
ARG VITE_IMAGEKIT_URL_ENDPOINT
ARG VITE_SENTRY_DSN=
ENV VITE_CLERK_PUBLISHABLE_KEY=$VITE_CLERK_PUBLISHABLE_KEY
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_IMAGEKIT_URL_ENDPOINT=$VITE_IMAGEKIT_URL_ENDPOINT
ENV VITE_SENTRY_DSN=$VITE_SENTRY_DSN

RUN npm run build
# produces ./dist — static HTML/JS/CSS

# --- Stage 2: serve with Nginx ---
FROM nginx:1.27-alpine AS runner
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
