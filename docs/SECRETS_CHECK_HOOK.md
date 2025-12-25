# Git Secrets Check Hook Documentation

## Summary

This repository includes a pre-commit Git hook that automatically scans staged
files for potential secrets, API keys, passwords, tokens, and other sensitive
credentials before allowing commits. This prevents accidental exposure of
sensitive information in your Git repository.

## Security Features

The secrets check hook protects against common security vulnerabilities:

- **Pattern-based Detection**: Scans for 15+ common secret patterns
- **Multiple Secret Types**: Detects API keys, passwords, tokens, private keys,
  and more
- **Case-Insensitive Matching**: Finds secrets regardless of capitalization
- **Commit Blocking**: Prevents commits if secrets are detected
- **Detailed Reporting**: Shows exact lines where secrets were found
- **File Exemptions**: Allows specific files to be excluded from scanning
- **Binary File Handling**: Automatically skips binary and non-text files

## Files for Hook

### Pre-commit Hook

- **Location**: `hooks/pre-commit.d/01-secrets-check.sh`
- **Purpose**: Scans all staged files for potential secrets before commit
- **Runs**: Before every commit
- **Exit Code**: Returns 1 (blocks commit) if secrets are found, 0 (allows
  commit) otherwise

## Detected Secret Types

The hook currently detects the following patterns:

1. **AWS Access Key ID**: `AKIA[0-9A-Z]{16}`
2. **AWS Secret Access Key**: `aws_secret_access_key = [40-character string]`
3. **Generic API Key**: `api_key = [20+ character string]`
4. **Generic Secret**: `secret = [20+ character string]`
5. **Generic Password**: `password = [8+ character string]`
6. **Private Key Headers**: `-----BEGIN PRIVATE KEY-----`
7. **GitHub Token**: `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` prefixes
8. **Generic Token**: `token = [20+ character string]`
9. **Google API Key**: `AIza[35-character string]`
10. **Slack Token**: `xoxb-`, `xoxa-`, `xoxp-`, `xoxr-`, `xoxs-` prefixes
11. **Stripe Live Key**: `sk_live_[24+ character string]`
12. **JWT Token**: `eyJ...eyJ...` format
13. **SSH Private Keys**: DSA and EC private key headers
14. **PGP Private Key**: `-----BEGIN PGP PRIVATE KEY BLOCK-----`
15. **Database Connection Strings**: MongoDB, MySQL, PostgreSQL, Postgres URIs
    with credentials
16. **Custom Test Pattern**: `XAVIERSECRET` (for testing purposes)

## Setup Instructions

### 1. Install the Hook

The hook should already be installed if you've cloned this repository with hooks
enabled. If not:

```bash
# Copy the pre-commit dispatcher to .git/hooks/
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Ensure the secrets check script is executable.
chmod +x hooks/pre-commit.d/01-secrets-check.sh
```

### 2. Verify Installation

Test that the hook is working:

```bash
# Create a test file with a secret.
echo "API_KEY=AKIAIOSFODNN7EXAMPLE" > test_secrets.txt
git add test_secrets.txt
git commit -m "Test commit"
```

The commit should be blocked with a message showing the detected secret.

### 3. Configure File Exemptions (Optional)

To exempt specific files from secrets scanning, edit the `FILE_EXEMPTIONS` array
in `hooks/pre-commit.d/01-secrets-check.sh`:

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

## Usage

### Normal Workflow

1. Add and stage files as usual:

```bash
git add myfile.py
git commit -m "Add new feature"
```

2. The pre-commit hook automatically runs and:
   - Scans all staged files (excluding deleted files)
   - Checks each file against all secret patterns
   - Reports any matches with line numbers
   - Blocks the commit if secrets are found

### When Secrets Are Detected

If secrets are found, you'll see output like:

```
Starting secrets check...
[!] Found potential secret in: config.py
    Pattern matched: Secret Pattern 3
    12:api_key = "AKIAIOSFODNN7EXAMPLE"

========================================
COMMIT BLOCKED: Found 1 potential secret(s) in 1 file(s).

Files with secrets:
  - config.py

Please remove the secrets from the files above and try again.
Consider using environment variables or configuration files for sensitive data.

If this was a mistake, you can edit the pre-commit hook for secrets in .git/hooks/pre-commit.d/##-secrets-check.sh.
========================================
```

### Remediation Steps

1. **Remove the secret** from the file:

```bash
# Replace with environment variable.
echo "api_key = os.environ.get('API_KEY')" >> config.py
```

2. **Use configuration files**:

```bash
# Move to config file (git-ignored).
echo "API_KEY=AKIAIOSFODNN7EXAMPLE" >> .env
```

3. **Stage the corrected file** and commit again:

```bash
git add config.py
git commit -m "Add new feature"
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

## Troubleshooting

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

### False Positives

If the hook incorrectly flags non-sensitive data:

1. **Add to exemptions**: Include the file in `FILE_EXEMPTIONS`
2. **Refine the pattern**: Modify the regex in `SECRET_PATTERNS` to be more
   specific
3. **Use comments**: Add a comment explaining why it's not a real secret

### Hook Not Running

Check that the hook is executable:

```bash
chmod +x .git/hooks/pre-commit
chmod +x hooks/pre-commit.d/01-secrets-check.sh
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

## Technical Details

### How It Works

1. **Pre-commit trigger**: Git calls the hook before creating a commit
2. **Get staged files**: Hook retrieves list of staged files using `git diff
--cached`
3. **File filtering**: Skips binary, exempted, and non-text files
4. **Pattern matching**: Uses `grep -iEq` for case-insensitive regex matching
5. **Result reporting**: Displays matching lines with line numbers
6. **Exit code**: Returns 1 to block commit if secrets found

### Regular Expression Details

The hook uses Extended Regular Expressions (ERE) with:

- **Case-insensitive matching**: `-i` flag in grep
- **Extended regex syntax**: `-E` flag for patterns like `\s`, `+`, etc.
- **Quiet mode**: `-q` flag for existence check (used with `-i`, `-E`)
- **Word boundaries**: Uses `\s` for whitespace matching

### Performance Considerations

- **Scan time**: Depends on number and size of staged files
- **Binary skip**: Speeds up scanning by skipping binary files early
- **Directory exclusions**: Improves performance by skipping large directories

## Customization Examples

### Adding a Company-Specific Secret Pattern

```bash
SECRET_PATTERNS=(
    # ... existing patterns ...

    # Company internal token format.
    'COMPANY_TOKEN_[A-F0-9]{32}'

    # Company API key format.
    'cmp_[a-z]{4}_[0-9]{12}'
)
```

### Exempting Test Files

```bash
FILE_EXEMPTIONS=(
    '01-secrets-check.sh'
    'tests/fixtures/sample_secrets.txt'
    'docs/security_examples.md'
)
```

### Creating a Whitelist for Specific Strings

Some strings may look like secrets but aren't. Modify the script to add a
whitelist:

```bash
# Add after SECRET_PATTERNS definition.
WHITELIST_STRINGS=(
    'example_api_key_not_real'
    'SAMPLE_SECRET_FOR_DOCS'
    'test_token_12345'
)

# In the pattern matching loop, add:
if [[ "${WHITELIST_STRINGS[@]}" =~ "$MATCHED_STRING" ]]; then
    continue
fi
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

### Pre-receive Hook

Adapt this script as a server-side pre-receive hook to prevent secrets from
reaching the remote repository.

### Logging

Add logging for audit purposes:

```bash
# Add to the script.
LOG_FILE=".git/logs/secrets-check.log"
echo "[$(date)] Secret check: $FOUND_SECRETS secrets found" >> "$LOG_FILE"
```

## Related Documentation

- [ENCRYPTION_HOOKS.md](./ENCRYPTION_HOOKS.md): Documentation for file
  encryption hooks
- [Git Hooks Documentation](https://git-scm.com/docs/githooks): Official Git
  hooks reference

## License

This hook is provided as-is for use in your projects.
