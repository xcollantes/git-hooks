# Git Hooks Cheatsheet

Collection of Git hooks and how to use them.

## How to Include in a Repository

The hooks are stored in the `hooks` directory. But locally they would normally
be stored in the `.git/hooks` directory.

1. Choose the desired hook, copy.
2. Paste hook file and directories if it applies into the `.git/hooks` directory
   for the desired repository.
3. Make the hook files executable.

```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit.d/*
```

## Secret Scanning

## Encrypt and Decrypt

Coming Soon.

## Hooks Management

Approaches to managing hooks.

I'll help you understand how to handle multiple git hook files for pre-commit.
Let me first check what you currently have set up.

[3 tools called]

Great question! Git natively only allows **one file per hook type** (like
`pre-commit`), but there are several ways to run multiple hook scripts:

### Approach 1: Single Dispatcher Hook (Recommended & Simple)

Create a single `pre-commit` hook that executes multiple scripts from a
directory:

```bash
#!/bin/bash
# .git/hooks/pre-commit

HOOK_DIR="$(git rev-parse --show-toplevel)/hooks/pre-commit.d"

# Exit on first error (if any hook fails, stop the commit)
set -e

# Run all executable files in the pre-commit.d directory
if [ -d "$HOOK_DIR" ]; then
    for hook in "$HOOK_DIR"/*; do
        if [ -x "$hook" ]; then
            echo "Running hook: $(basename "$hook")"
            "$hook"
            # Check exit status
            if [ $? -ne 0 ]; then
                echo "Hook $(basename "$hook") failed!"
                exit 1
            fi
        fi
    done
fi

exit 0
```

Then organize your hooks like this:

```bash
hooks/
  pre-commit.d/
    01-secret-scan.sh
    02-encrypt-files.sh
    03-lint-check.sh
```

Make each script executable: `chmod +x hooks/pre-commit.d/*.sh`

### Approach 2: Use a Hook Manager

**Option A: pre-commit framework** (Python-based, popular)

```bash
pip install pre-commit
```

Create a `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: secret-scan
        name: Secret Scanner
        entry: ./hooks/secret-scan.sh
        language: system

      - id: encrypt-files
        name: Encrypt Sensitive Files
        entry: ./hooks/encrypt.sh
        language: system
```

**Option B: Husky** (Node.js projects)

### Approach 3: Chain Scripts in Single Hook

Simple inline approach in `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Run first hook
./hooks/secret-scan.sh || exit 1

# Run second hook
./hooks/encrypt-files.sh || exit 1

# Run third hook
./hooks/lint-check.sh || exit 1

exit 0
```
