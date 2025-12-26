# Local Branch Block Hook Documentation

## Summary

This repository includes a pre-push Git hook that prevents pushing branches
containing "local/" in their name to remote repositories. This ensures that
branches meant for local development and experimentation stay on your machine
and don't clutter the remote repository.

**NOTE**: The hooks will all run as long a they are in the `.git/hooks` directory.
To exclude a hook, remove it to the `hooks` directory. To skip all hooks, use
`git push --no-verify origin branch-name` flag.

## Features

The local branch block hook provides:

- **Push Blocking**: Prevents push operations for branches containing "local/"
- **Naming Convention Enforcement**: Encourages consistent branch naming
  practices
- **Bypassing the Hook**: Only use `git push --no-verify` when absolutely
  necessary.

## Files for Hook

### Pre-push Hook Script

- **Location**: `hooks/pre-push.d/##-block-local-branch.sh`
- **Purpose**: Blocks pushes for branches with "local/" in the name
- **Runs**: Before every push operation
- **Exit Code**: Returns 1 (blocks push) if branch contains "local/", 0 (allows
  push) otherwise

## Setup Instructions

### 1. Copy the Hook to the Repository's hooks

```bash
# Copy the pre-push hook to hooks/
cp hooks/pre-push.d/01-block-local-branch.sh .git/hooks/pre-push.d/01-block-local-branch.sh

# Ensure the hook is executable
chmod +x .git/hooks/pre-push.d/01-block-local-branch.sh
```

### 2. Verify the Hook is Working

Test that the hook is working by creating a branch with "local/" in the name and
trying to push it:

```bash
# Create a test branch with "local/" in the name
git checkout -b local/test

# Make a small change
echo "test" > test.txt
git add test.txt
git commit -m "Test commit"

# Try to push (this should be blocked)
git push origin local/test
```

The push should be blocked with a message.

```
WAIT!: Cannot push branch 'local/test-feature' to remote.
Branches containing 'local/' are restricted to local development only.
```

### 3. Clean Up Test Branch

```bash
# Switch back to main branch
git checkout main

# Delete the test branch
git branch -D local/test-feature
```

## How It Works

The hook performs the following steps:

1. **Read Push Information**: Receives branch references from Git via stdin
2. **Extract Branch Name**: Parses the reference to get the branch name
3. **Pattern Matching**: Checks if the branch name contains "local/"
4. **Block or Allow**: Exits with code 1 to block, or 0 to allow the push

## Bypassing the Hook

### Add --no-verify to the push command

In rare cases where you need to bypass the hook:

```bash
git push --no-verify origin local/branch-name
```

**WARNING**: Only use `--no-verify` when absolutely necessary. The hook exists
to prevent local branches from cluttering the remote repository.

### Rename the branch to remove "local/" prefix

Instead of bypassing, consider renaming the branch:

```bash
# Rename the branch to remove "local/" prefix
git branch -m local/feature feature/feature
```

## Pitfalls

### Hook Not Running

Verify the hook is executable:

```bash
ls -l .git/hooks/pre-push
```

Should show: `-rwxr-xr-x` (executable permissions)

If not executable:

```bash
chmod +x .git/hooks/pre-push
chmod +x hooks/pre-push.d/01-block-local-branch.sh
```

### Hook Blocks Wrong Branches

Check if your branch name contains "local/" anywhere:

```bash
# Show current branch name
git branch --show-current
```

The hook blocks any branch with "local/" in the name, including:

- `local/feature`
- `feature/local/test`
- `mylocal/branch`

### Already Pushed a Local Branch

If you accidentally pushed a local branch before installing the hook:

```bash
# Delete the remote branch
git push origin --delete local/branch-name

# Keep or delete your local branch
git branch -D local/branch-name  # Delete
# OR
git branch -m local/branch-name feature/new-name  # Rename
```

## Limitations

- **Pattern-based**: Only checks for the string "local/" in branch names
- **No remote validation**: Doesn't check if the branch already exists remotely
- **Case-sensitive**: "LOCAL/" or "Local/" will not be blocked
- **Push-time only**: Doesn't prevent branch creation, only pushing
- **Single pattern**: Only blocks "local/", not other private prefixes

## Advanced Configuration

### Adding Additional Blocked Patterns

To block additional patterns, edit `hooks/pre-push.d/01-block-local-branch.sh`:

```bash
# Check for multiple patterns
if [[ "$branch_name" == *"local/"* ]] || \
   [[ "$branch_name" == *"private/"* ]] || \
   [[ "$branch_name" == *"temp/"* ]]; then
    echo "WAIT!: Cannot push branch '$branch_name' to remote."
    echo "Branches containing 'local/', 'private/', or 'temp/' are restricted."
    exit 1
fi
```

### Case-Insensitive Matching

For case-insensitive matching, modify the comparison:

```bash
# Convert to lowercase for comparison
branch_lower=$(echo "$branch_name" | tr '[:upper:]' '[:lower:]')

if [[ "$branch_lower" == *"local/"* ]]; then
    echo "WAIT!: Cannot push branch '$branch_name' to remote."
    exit 1
fi
```
