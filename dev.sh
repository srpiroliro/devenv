#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "Error at line $LINENO. Aborting." >&2' ERR

# script_dir="/home/user/Documents/devcontainer" # "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
get_script_dir() {
  local SOURCE="${BASH_SOURCE[0]}"
  while [ -L "$SOURCE" ]; do
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$(dirname "${BASH_SOURCE[0]}")/$SOURCE"
  done
  dirname "$(readlink -f "$SOURCE")"
}

script_dir="$(get_script_dir)/helpers"

DC="docker compose -f docker-compose.dev.yml"

_err_missing() {
  echo "Error: $1 not found in $(pwd)" >&2
  exit 1
}

ensure_required_files() {
  [[ -f "docker-compose.dev.yml" ]] || _err_missing "docker-compose.dev.yml"
  [[ -f "dev.Dockerfile" ]]         || _err_missing "dev.Dockerfile"
  [[ -f ".dockerignore" ]]          || _err_missing ".dockerignore"
}

# Commands

pr()        { ensure_required_files; $DC run --rm app pnpm prisma "$@"; }
prstudio()  { pr; }
prgen()     { pr generate; }
prpush()    { pr db push; }
prpull()    { pr db pull; }
prmigrate() { pr migrate dev; }
prmstat()   { pr migrate status; }

install() {
  ensure_required_files

  # Install locally with --ignore-scripts
  if command -v pnpm >/dev/null 2>&1; then
    echo "Installing locally with --ignore-scripts..."
    pnpm install "$@" --ignore-scripts
  else
    echo "Warning: pnpm not found locally, skipping local install"
  fi

  # Install in container normally
  echo "Installing in container..."
  $DC run --rm app pnpm install "$@"
}

shell() {
  ensure_required_files
  $DC up -d
  $DC exec app sh
}

add() {
  ensure_required_files
  $DC run --rm app pnpm add "$@" --lockfile-only
  cid=$($DC ps -q app) || true
  if [[ -z ${cid-} ]]; then echo "Error: container not running" >&2; exit 1; fi
  docker cp "${cid}:/app/package.json" ./package.json
  docker cp "${cid}:/app/pnpm-lock.yaml" ./pnpm-lock.yaml
  install
}

run() {
  ensure_required_files
  $DC run --rm app pnpm run "$@"
}

build() {
  ensure_required_files
  $DC run --rm app pnpm run build
}

start() {
  ensure_required_files
  $DC up -d --build
}

stop() {
  ensure_required_files
  $DC down
}

logs() {
  ensure_required_files
  $DC logs -f "$@"
}

status() {
  ensure_required_files
  $DC ps
}

quit() {
  ensure_required_files
  $DC down
  exit 0
}

handle_dockerignore() {
  template="$script_dir/.dockerignore"
  target=".dockerignore"

  if [ ! -f "$template" ]; then
    echo "Template .dockerignore not found in $script_dir"
    return
  fi

  if [ ! -f "$target" ]; then
    cp "$template" "$target"
    echo "Copied .dockerignore template"
  else
    while IFS= read -r line; do
      grep -Fxq "$line" "$target" || echo "$line" >> "$target"
    done < "$template"
    echo "Appended missing lines to existing .dockerignore"
  fi
}

handle_gitignore() {
  target=".gitignore"
  files_to_add=("dev.Dockerfile" "docker-compose.dev.yml" ".pnpm-store")

  # Add .dockerignore only if it doesn't already exist in the target directory
  if [ ! -f ".dockerignore" ]; then
    files_to_add+=(".dockerignore")
  fi

  if [ ! -f "$target" ]; then
    for file in "${files_to_add[@]}"; do
      echo "$file" >> "$target"
    done
    echo "Created .gitignore with dev environment files"
  else
    for file in "${files_to_add[@]}"; do
      grep -Fxq "$file" "$target" || echo "$file" >> "$target"
    done
    echo "Added missing dev environment files to .gitignore"
  fi
}

# New: initialize project with dev environment
init() {
  for file in dev.Dockerfile .dockerignore docker-compose.dev.yml; do
    cp "$script_dir/$file" "./$file"
  done

  handle_dockerignore
  handle_gitignore

  echo "✅ Dev environment files initialized in $(pwd)"
  exit 0
}

# Help on no args or unknown
if [[ "$#" -eq 0 ]]; then
  echo "Usage: dev <command>"
  echo
  cat <<EOF
Available commands:

Container Management:
  init         — Copy dev environment files into current directory
  start        — Start the dev server containers in detached mode
  stop         — Stop and remove the dev server containers
  status       — Show status of running containers
  logs [svc]   — View and follow container logs (optionally for specific service)
  shell        — Open interactive shell inside container
  quit         — Stop containers and exit

Package Management:
  install [pkg] — Install packages locally (with --ignore-scripts) and in container
  add <pkg>     — Add pkg(s) to package.json & lockfile, then install
  run <script>  — Execute npm/pnpm script from package.json

Database (Prisma):
  pr <cmd>     — Run any Prisma CLI command
  prstudio     — Launch Prisma Studio
  prgen        — Generate Prisma client (prisma generate)
  prpush       — Push schema to database (prisma db push)
  prpull       — Pull schema from database (prisma db pull)
  prmigrate    — Run database migrations (prisma migrate dev)
  prmstat      — Check migration status (prisma migrate status)

Examples:
  dev init                                    # Initialize dev environment
  dev start                                   # Start containers
  dev status                                  # Check container status
  dev install                                 # Install all packages locally and in container
  dev install lodash                          # Install specific package locally and in container
  dev logs                                    # View all logs
  dev logs app                                # View app container logs only
  dev run build                               # Run build script
  dev run test                                # Run test script
  dev add @rainbow‑me/rainbowkit wagmi viem    # Add packages
  dev pr migrate reset                        # Run custom Prisma command
  dev shell                                   # Open interactive shell
  dev quit                                    # Stop containers and exit

All commands run inside Docker containers and require package.json in your project.
EOF
  exit 0
fi

"$@"
