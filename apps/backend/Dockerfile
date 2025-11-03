# ==========================================
# Stage 1: Base Image Setup
# ==========================================
FROM node:18-alpine AS base

# Install pnpm with specific version for reproducibility
RUN npm install -g pnpm@8.15.0

WORKDIR /app

# Copy workspace configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# ==========================================
# Stage 2: Install Dependencies
# ==========================================
FROM base AS dependencies

# Copy package.json files for dependency installation
COPY apps/contract/package.json ./apps/contract/package.json
COPY apps/backend/package.json ./apps/backend/package.json

# Install ALL dependencies (including dev dependencies needed for build)
RUN pnpm install --frozen-lockfile

# ==========================================
# Stage 3: Build Application
# ==========================================
FROM base AS build

# Copy node_modules from dependencies stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy source code
COPY apps/contract ./apps/contract
COPY apps/backend ./apps/backend

# Set working directory to backend
WORKDIR /app/apps/backend

# Build the application
RUN pnpm run build

# ==========================================
# Stage 4: Production Image
# ==========================================
FROM node:18-alpine AS production

# Install pnpm
RUN npm install -g pnpm@8.15.0

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001

# Set production environment
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max_old_space_size=2048

WORKDIR /app

# Copy workspace configuration
COPY --chown=nestjs:nodejs package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Copy package.json files
COPY --chown=nestjs:nodejs apps/contract/package.json ./apps/contract/package.json
COPY --chown=nestjs:nodejs apps/backend/package.json ./apps/backend/package.json

# Install ONLY production dependencies
RUN pnpm install --prod --frozen-lockfile

# Copy contract files (if needed at runtime)
COPY --chown=nestjs:nodejs --from=build /app/apps/contract ./apps/contract

# Copy built backend application
COPY --chown=nestjs:nodejs --from=build /app/apps/backend/dist ./apps/backend/dist

# Set working directory
WORKDIR /app/apps/backend

# Switch to non-root user
USER nestjs

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Expose port
EXPOSE 3000

# Start application directly with node (faster than pnpm start)
CMD ["node", "dist/main.js"] 

# Use the official Node.js 18 image
# FROM node:18-alpine

# # Increase Node.js memory limit
# ENV NODE_OPTIONS=--max_old_space_size=4096

# # Set working directory
# WORKDIR /app

# # Install pnpm
# RUN npm install -g pnpm

# # Copy 'package.json' and 'pnpm-lock.yaml' from the service directory
# COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# # Copy the 'contract' folder and any other dependencies
# COPY apps/contract apps/contract

# # Copy the 'contract' folder and any other dependencies
# COPY apps/backend apps/backend

# # Install dependencies using pnpm
# RUN pnpm install

# WORKDIR /app/apps/backend

# # Build the service
# RUN pnpm run build

# # Set the command to run your service
# CMD ["pnpm", "start"]

# # Expose port 3000
# EXPOSE 3000
