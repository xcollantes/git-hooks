# Git Secrets Check Hook Documentation

## Summary

This repository includes a pre-commit Git hook that automatically scans staged
files for potential secrets, API keys, passwords, tokens, and other sensitive
credentials before allowing commits. This prevents accidental exposure of
sensitive information in your Git repository.

**NOTE**: The hooks will all run as long a they are in the `.git/hooks` directory.
To exclude a hook, remove it to the `hooks` directory. To skip all hooks, use
`git commit --no-verify -m "COMMIT MESSAGE"` flag.

## Security Features

The secrets check hook protects against common security vulnerabilities:

- **Pattern-based Detection**: Scans for 15+ common secret patterns
- **Commit Blocking**: Prevents commits if secrets are detected
- **Detailed Reporting**: Shows exact lines where secrets were found
- **File Exemptions**: Allows specific files to be excluded from scanning
- **Binary File Handling**: Automatically skips binary and non-text files
- **Bypassing the Hook**: Only use `git commit --no-verify` when absolutely
  necessary.

## Files for Hook

### Pre-commit Hook

- **Location**: `hooks/pre-commit.d/01-secrets-check.sh`
- **Purpose**: Scans all staged files for potential secrets before commit
- **Runs**: Before every commit
- **Exit Code**: Returns 1 (blocks commit) if secrets are found, 0 (allows
  commit) otherwise

## Setup Instructions

### 1. Copy the Hook to the Repository's .git/hooks

```bash
# Copy the pre-commit dispatcher to .git/hooks/
cp hooks/pre-commit .git/hooks/pre-commit

# Ensure the secrets check script is executable.
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit.d/*
```

### 2. Verify the Hook is Working

Test that the hook is working:

```bash
# Create a test file with a secret.
echo "API_KEY=AKIAIOSFODNN7EXAMPLE" > test_secrets.txt
git add test_secrets.txt
git commit -m "Test commit which should be blocked"
```

The commit should be blocked with a message showing the detected secret.

### 3. Configure File Exemptions (Optional)

To exempt specific files from secrets scanning, edit the `FILE_EXEMPTIONS` array
in `.git/hooks/pre-commit.d/##-secrets-check.sh`:

```bash
FILE_EXEMPTIONS=(
    '01-secrets-check.sh'
    'test_fixtures/expected_secrets.txt'
    'docs/examples.md'
)
```

### 4. Add Custom Secret Patterns (Optional)

To detect additional secret types, add patterns to the `SECRET_PATTERNS` array:

```bash
SECRET_PATTERNS=(
    # ... existing patterns ...

    # Your custom pattern.
    'company_secret_key\s*=\s*["\047]?[A-Za-z0-9]{32}["\047]?'
)
```

## Remediation Steps

### Remove the secret from the file

```bash
# Replace with environment variable.
echo "API_KEY=AKIAIOSFODNN7EXAMPLE" >> config.secret
```

### Bypassing the Hook (Not Recommended)

In rare cases where you need to bypass the hook:

```bash
git commit --no-verify -m "Emergency commit"
```

**WARNING**: Only use `--no-verify` when absolutely necessary and you're certain
no secrets are present.

## Files Automatically Skipped

The hook automatically skips:

- **Binary files**: Detected via `file` command
- **Deleted files**: Files removed from the repository
- **Image files**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.ico`
- **Archive files**: `.pdf`, `.zip`, `.tar`, `.gz`, `.bz2`
- **Executable files**: `.exe`, `.dll`, `.so`, `.dylib`
- **Common directories**: `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`
- **Exempted files**: Files listed in `FILE_EXEMPTIONS` array

## Security Best Practices

1. **Never bypass the hook** unless you have a legitimate reason
2. **Use environment variables** for sensitive data instead of hardcoding
3. **Store secrets in configuration files** that are git-ignored (e.g., `.env`)
4. **Use secret management tools** like HashiCorp Vault, AWS Secrets Manager, or
   1Password
5. **Rotate secrets immediately** if they are accidentally committed
6. **Review patterns regularly** to ensure they cover new secret types
7. **Educate team members** about the importance of secrets management
8. **Use `.gitignore`** to prevent secret files from being staged

## Team Collaboration

### For New Team Members:

1. Clone the repository with hooks enabled
2. Verify the hook is installed: `ls -la .git/hooks/pre-commit`
3. Review the detected secret patterns: `cat
hooks/pre-commit.d/01-secrets-check.sh`
4. Learn about proper secrets management practices

### For Existing Team Members:

- The hook runs automatically on every commit
- If you find false positives, add the file to `FILE_EXEMPTIONS`
- If you discover new secret types, add patterns to `SECRET_PATTERNS`

## Pitfalls

### "grep: command not found"

Install `grep`:

```bash
# macOS (should be pre-installed).
xcode-select --install

# Linux (Debian/Ubuntu).
sudo apt-get install grep

# Linux (RedHat/CentOS).
sudo yum install grep
```

### Secret Already Committed

If a secret was already committed to history:

1. **Remove from Git history**:

```bash
# Using git filter-branch (caution: rewrites history).
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty --tag-name-filter cat -- --all
```

2. **Rotate the secret immediately**: Change the compromised credential

3. **Force push** (if working on a team, coordinate first):

```bash
git push origin --force --all
```

## Limitations

- **Regex-based detection**: May produce false positives or miss obfuscated
  secrets
- **No entropy analysis**: Does not analyze randomness of strings
- **Staged files only**: Only scans files that are staged (not entire working
  directory)
- **Pattern-dependent**: Only detects known patterns (new secret types need new
  patterns)
- **Performance impact**: Large repositories with many staged files may
  experience delays

## Advanced Features

### Integration with CI/CD

Use the same script in CI/CD pipelines:

```bash
# In your CI pipeline.
bash hooks/pre-commit.d/01-secrets-check.sh
```
