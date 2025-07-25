# Dev Environment Tool

A containerized development environment wrapper for Node.js/Prisma projects using Docker Compose.

## Installation

To install the `dev` command globally, create a symlink to the script in a directory that's in your `$PATH`:

### Option 1: System-wide installation (requires sudo)
```bash
sudo ln -s /path/to/dev.sh /usr/local/bin/dev
```

### Option 2: User-local installation
```bash
# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Create symlink
ln -s /path/to/dev.sh ~/.local/bin/dev

# Ensure ~/.local/bin is in your PATH (add to ~/.bashrc or ~/.zshrc if needed)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Option 3: Using any directory in your PATH
```bash
# Example using /usr/bin (requires sudo)
sudo ln -s /path/to/dev.sh /usr/bin/dev

# Or any other directory in your PATH
ln -s /path/to/dev.sh /your/path/directory/dev
```

Replace `/path/to/dev.sh` with the actual path to your dev.sh file.

## Usage

After installation, you can use the `dev` command from anywhere:

```bash
dev init        # Initialize dev environment in current project
dev start       # Start containers
dev run build   # Run npm/pnpm scripts
dev shell       # Open interactive shell
```

Run `dev` without arguments to see all available commands and examples.