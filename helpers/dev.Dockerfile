FROM node:20-alpine AS base
WORKDIR /app

RUN apk update && apk add --no-cache openssl libc6-compat

# Ensure pnpm available
RUN npm install -g pnpm@latest

# Copy lockfile if exists

COPY package.json pnpm-lock.yaml* ./

# Copy Prisma schema early to enable prisma generate
COPY prisma* ./prisma

# Install dependencies based on presence of lockfile
RUN if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; \
    else pnpm install; fi

# Generate Prisma client
RUN pnpm prisma generate || true

COPY . .

# keep it alive
CMD ["tail", "-f", "/dev/null"]
