#!/bin/bash
# Pre-commit hook to detect and replace secrets in staged files.
# This script checks for common patterns like API keys, passwords, tokens, etc.

set -e

FILE_EXEMPTIONS=(
    '01-secrets-check.sh'
)

# Define regex patterns for common secrets.
# Add more patterns as needed.
SECRET_PATTERNS=(
    # Xavier test key
    'XAVIERSECRET'
    # AWS Access Key ID
    'AKIA[0-9A-Z]{16}'
    # AWS Secret Access Key
    'aws_secret_access_key\s*=\s*["\047]?[A-Za-z0-9/+=]{40}["\047]?'
    # Generic API Key
    'api[_-]?key\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}["\047]?'
    # Generic Secret
    'secret\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}["\047]?'
    # Generic Password
    'password\s*[=:]\s*["\047]?[^\s"\047]{8,}["\047]?'
    # Private Key Header
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
    # GitHub Token
    'gh[pousr]_[A-Za-z0-9_]{36,}'
    # Generic Token
    'token\s*[=:]\s*["\047]?[A-Za-z0-9_\-]{20,}["\047]?'
    # Google API Key
    'AIza[0-9A-Za-z_\-]{35}'
    # Slack Token
    'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[A-Za-z0-9]{24,}'
    # Stripe Key
    'sk_live_[0-9a-zA-Z]{24,}'
    # JWT Token
    'eyJ[A-Za-z0-9_\-]*\.eyJ[A-Za-z0-9_\-]*\.[A-Za-z0-9_\-]*'
    # SSH Private Key (DSA)
    '-----BEGIN DSA PRIVATE KEY-----'
    # SSH Private Key (EC)
    '-----BEGIN EC PRIVATE KEY-----'
    # PGP Private Key
    '-----BEGIN PGP PRIVATE KEY BLOCK-----'
    # Database Connection String
    '(mongodb|mysql|postgres|postgresql):\/\/[^\s]*:[^\s]*@[^\s]+'
)

FOUND_SECRETS=0
FILES_WITH_SECRETS=()

echo "Starting secrets check..."

# Get list of staged files (excluding deleted files).
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "No staged files to check."
    exit 0
fi

# Check each staged file.
for FILE in $STAGED_FILES; do

    # Skip binary files and files in certain directories.
    if [ ! -f "$FILE" ]; then
        continue
    fi

    # Skip exempted files.
    if [[ "${FILE_EXEMPTIONS[@]}" =~ "${FILE}" ]]; then
        continue
    fi

    # Check if file is binary, skip if so.
    if file "$FILE" | grep -q "binary"; then
        continue
    fi

    # Skip certain file types/directories.
    if [[ "$FILE" =~ \.(jpg|jpeg|png|gif|ico|pdf|zip|tar|gz|bz2|exe|dll|so|dylib)$ ]] || \
       [[ "$FILE" =~ ^(node_modules|vendor|\.git|dist|build)/ ]]; then
        continue
    fi

    # Check each pattern.
    for i in "${!SECRET_PATTERNS[@]}"; do
        PATTERN="${SECRET_PATTERNS[$i]}"
        PATTERN_NAME="Secret Pattern $((i+1))"

        # Search for pattern in file (case-insensitive).
        if grep -iEq -- "$PATTERN" "$FILE"; then
            echo "[!] Found potential secret in: ${FILE}"
            echo "    Pattern matched: ${PATTERN_NAME}"

            # Show the matching lines (with line numbers).
            grep -inE -- "$PATTERN" "$FILE" | while read -r line; do
                echo "    ${line}"
            done

            FOUND_SECRETS=$((FOUND_SECRETS + 1))

        fi
    done

    FILES_WITH_SECRETS+=("$FILE")
    echo "Secrets found in: ${FILE}"

done

# Summary.
echo ""
echo "========================================"
if [ $FOUND_SECRETS -gt 0 ]; then
    echo "COMMIT BLOCKED: Found $FOUND_SECRETS potential secret(s) in ${#FILES_WITH_SECRETS[@]} file(s)."
    echo ""
    echo "Files with secrets:"
    for FILE in "${FILES_WITH_SECRETS[@]}"; do
        echo "  - ${FILE}"
    done
    echo ""
    echo "Please remove the secrets from the files above and try again."
    echo "Consider using environment variables or configuration files for sensitive data."
    echo ""
    echo "If this was a mistake, you can edit the pre-commit hook for secrets in .git/hooks/pre-commit.d/##-secrets-check.sh."
else
    echo "No secrets detected. Safe to commit!"
fi
echo "========================================"

# Exit with error code if secrets were found to block the commit.
if [ $FOUND_SECRETS -gt 0 ]; then
    exit 1
fi

exit 0