# Multi-stage Dockerfile for Strapi v5 (Node 20)

# ---- Base image ----
FROM node:20-alpine AS base

# Set working directory
WORKDIR /app

# Install system dependencies (if needed for native modules)
RUN apk add --no-cache bash libc6-compat

# ---- Dependencies layer ----
FROM base AS deps

# Copy dependency manifests
COPY package.json package-lock.json ./

# Install dependencies (ci is faster & reproducible)
RUN npm ci

# ---- Build layer ----
FROM deps AS builder

# Copy the rest of the app
COPY . .

# Build Strapi admin panel
RUN npm run build

# ---- Production runtime ----
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Install only production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy built app from builder
COPY --from=builder /app .

# Expose Strapi default port
EXPOSE 1337

# Healthcheck (optional)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD node -e "require('http').get('http://localhost:1337/admin', () => process.exit(0)).on('error', () => process.exit(1))"

# Start Strapi
CMD ["npm", "run", "start"]
