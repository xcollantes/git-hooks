#!/bin/bash
# Pre-commit hook to encrypt sensitive files before committing.
# Uses GPG with strong cipher algorithms for maximum security.
# Prioritizes security over speed.

set -e

# Configuration file path.
CONFIG_FILE="$(git rev-parse --show-toplevel)/.git/encrypt-config"

# Files to encrypt (regex patterns).
ENCRYPT_FILENAME_PATTERNS=(
    '*.txt'
    '*.md'
    '*.sh'
    '*.py'
    '*.json'
    '*.yaml'
    '*.yml'
    '*.xml'
    '*.html'
    '*.css'
    '*.js'
    '*.pdf'
    '*.csv'
    '*.tsv'
    '*.sql'
    '*.db'
    '*.sqlite'
    '*.sqlite3'
    '*.sqlite3'
    '*.docx'
    '*.doc'
    '*.xls'
    '*.xlsx'
    '*.ppt'
    '*.pptx'
    '*.odt'
    '*.ods'
    '*.jpg'
    '*.jpeg'
    '*.png'
    '*.gif'
    '*.ico'
    '*.webp'
    '*.svg'
    '*.mp3'
    '*.mp4'
)

GPG_CIPHER_ALGO="AES256"
GPG_DIGEST_ALGO="SHA512"
GPG_COMPRESS_ALGO="ZLIB"
GPG_COMPRESS_LEVEL="9"
GPG_S2K_MODE="3"
GPG_S2K_DIGEST_ALGO="SHA512"
GPG_S2K_COUNT="65011712"

echo "Starting file encryption check..."

# Check if GPG is installed.
if ! command -v gpg &> /dev/null; then
    echo "[ERROR] GPG is not installed. Please install GPG to use encryption."
    echo "Install with: brew install gnupg (macOS) or apt-get install gnupg (Linux)"
    exit 1
fi

# Check for encryption key/passphrase.
ENCRYPTION_KEY_FILE="$(git rev-parse --show-toplevel)/.git/encryption-key"

if [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
    echo "[WARNING] No encryption key file found at $ENCRYPTION_KEY_FILE"
    echo "Creating a new encryption key file..."
    echo "Please enter a strong passphrase for encryption:"
    read -s PASSPHRASE < /dev/tty
    echo ""
    echo "Confirm passphrase:"
    read -s PASSPHRASE_CONFIRM < /dev/tty
    echo ""

    if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
        echo "[ERROR] Passphrases do not match."
        exit 1
    fi

    if [ ${#PASSPHRASE} -lt 20 ]; then
        echo "[WARNING] Passphrase is less than 20 characters. Consider using a longer passphrase."
    fi

    echo "$PASSPHRASE" > "$ENCRYPTION_KEY_FILE"
    chmod 600 "$ENCRYPTION_KEY_FILE"
    echo "[SUCCESS] Encryption key file created."
fi

# Read the passphrase.
PASSPHRASE=$(cat "$ENCRYPTION_KEY_FILE")

# Get list of staged files.
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$STAGED_FILES" ]; then
    echo "No staged files to check."
    exit 0
fi

ENCRYPTED_COUNT=0
SKIPPED_COUNT=0

# Function to check if a file matches any pattern.
matches_pattern() {
    local file="$1"
    for pattern in "${ENCRYPT_FILENAME_PATTERNS[@]}"; do

        # Convert glob pattern to regex.
        if [[ "$file" == $pattern ]]; then
            return 0
        fi

    done

    return 1

}

# Function to encrypt a file.
encrypt_file() {
    local file="$1"
    local encrypted_file="${file}.encrypted"

    echo "[ENCRYPTING] $file"

    # Use GPG with the most secure settings.
    # Symmetric encryption with AES-256, SHA-512, and maximum S2K iterations.
    echo "$PASSPHRASE" | gpg \
        --batch \
        --yes \
        --passphrase-fd 0 \
        --symmetric \
        --cipher-algo "$GPG_CIPHER_ALGO" \
        --digest-algo "$GPG_DIGEST_ALGO" \
        --compress-algo "$GPG_COMPRESS_ALGO" \
        --compress-level "$GPG_COMPRESS_LEVEL" \
        --s2k-mode "$GPG_S2K_MODE" \
        --s2k-digest-algo "$GPG_S2K_DIGEST_ALGO" \
        --s2k-count "$GPG_S2K_COUNT" \
        --force-mdc \
        --no-symkey-cache \
        --output "$encrypted_file" \
        "$file" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Add encrypted file to staging.
        git add "$encrypted_file"

        # Remove original file from staging (but keep in working directory).
        git reset -- "$file" >/dev/null 2>&1 || true

        echo "[SUCCESS] Encrypted: $file -> $encrypted_file"
        return 0
    else
        echo "[ERROR] Failed to encrypt: $file"
        return 1
    fi
}

# Process each staged file.
for FILE in $STAGED_FILES; do
    # Skip if file doesn't exist.
    if [ ! -f "$FILE" ]; then
        continue
    fi

    # Skip if already encrypted.
    if [[ "$FILE" == *.encrypted ]]; then
        continue
    fi

    # Check if file matches encryption patterns.
    if matches_pattern "$FILE"; then
        if encrypt_file "$FILE"; then
            ENCRYPTED_COUNT=$((ENCRYPTED_COUNT + 1))
        else
            echo "[ERROR] Encryption failed. Aborting commit."
            exit 1
        fi
    else
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
done

# Summary.
echo ""
echo "========================================"
echo "Encryption Summary:"
echo "  Files encrypted: $ENCRYPTED_COUNT"
echo "  Files skipped: $SKIPPED_COUNT"
echo ""
if [ $ENCRYPTED_COUNT -gt 0 ]; then
    echo "Files successfully encrypted and staged."
    echo "Original files remain in your working directory but are not staged."
    echo ""
    echo "To decrypt files after pulling, the post-merge hook will handle it automatically."
fi
echo "========================================"

exit 0
