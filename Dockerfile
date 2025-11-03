# Use the official Node.js 18 image
FROM node:18-alpine AS base

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Copy workspace configuration
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Dependencies stage

FROM base AS dependencies

# Copy workspace packages
COPY apps/contract apps/contract
COPY apps/backend apps/backend

# Install all dependencies
RUN pnpm install --frozen-lockfile

# Build stage
FROM base AS build

# Copy dependencies from previous stage
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=dependencies /app/apps ./apps

# Copy workspace configuration again
COPY apps/contract apps/contract
COPY apps/backend apps/backend

# Set working directory to backend
WORKDIR /app/apps/backend

# Build without database-dependent type generation
# Option 1: If you have pre-generated types in your repo
RUN pnpm run build

# Option 2: If you need to skip type generation, modify build script
# RUN nest build

# ==========================================
# Production stage
# ==========================================
FROM node:18-alpine AS production

# Install pnpm
RUN npm install -g pnpm

# Set NODE_ENV
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max_old_space_size=4096

WORKDIR /app

# Copy necessary files from build stage
COPY --from=build /app/package.json ./
COPY --from=build /app/pnpm-lock.yaml ./
COPY --from=build /app/pnpm-workspace.yaml ./
COPY --from=build /app/apps/contract ./apps/contract
COPY --from=build /app/apps/backend/dist ./apps/backend/dist
COPY --from=build /app/apps/backend/package.json ./apps/backend/

# Install only production dependencies
RUN pnpm install --prod --frozen-lockfile

WORKDIR /app/apps/backend

# Expose port
EXPOSE 3000

# Start the application
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
