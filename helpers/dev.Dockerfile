FROM node:20-alpine AS base

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN addgroup -g $GROUP_ID -S appgroup && \
    adduser -u $USER_ID -S appuser -G appgroup

RUN apk update && apk add --no-cache openssl libc6-compat

# Ensure pnpm available
RUN npm install -g pnpm@latest

WORKDIR /app
RUN chown -R appuser:appgroup /app

USER appuser

# Copy lockfile if exists
COPY --chown=appuser:appgroup package.json pnpm-lock.yaml* ./

# Copy Prisma schema early to enable prisma generate
COPY --chown=appuser:appgroup prisma* ./prisma

# Install dependencies based on presence of lockfile
RUN if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; \
    else pnpm install; fi

# Generate Prisma client
RUN pnpm prisma generate || true

COPY --chown=appuser:appgroup . .

# keep it alive
CMD ["tail", "-f", "/dev/null"]
