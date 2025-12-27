#!/bin/bash
# Post-checkout hook to decrypt files after checkout/clone operations.
# Uses GPG to decrypt files that were encrypted during pre-commit.

set -e

# Configuration.
ENCRYPTION_KEY_FILE=".git/encryption-key"

echo "Starting file decryption check..."

# Check if GPG is installed.
if ! command -v gpg &> /dev/null; then
    echo "[ERROR] GPG is not installed. Please install GPG to use decryption."
    echo "Install with: brew install gnupg (macOS) or apt-get install gnupg (Linux)"
    exit 1
fi

# Check for encryption key file.
if [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
    echo "[WARNING] No encryption key file found at $ENCRYPTION_KEY_FILE"
    echo "If you have encrypted files, please provide the passphrase:"
    read -s PASSPHRASE < /dev/tty
    echo ""

    if [ -z "$PASSPHRASE" ]; then
        echo "[WARNING] No passphrase provided. Skipping decryption."
        exit 0
    fi
else
    # Read the passphrase.
    PASSPHRASE=$(cat "$ENCRYPTION_KEY_FILE")
fi

# Find all .gpg files in the repository.
GPG_FILES=$(find . -type f -name "*.encrypted" -not -path "./.git/*" 2>/dev/null || true)

if [ -z "$GPG_FILES" ]; then
    echo "No encrypted files found."
    exit 0
fi

DECRYPTED_COUNT=0
FAILED_COUNT=0

# Function to decrypt a file.
decrypt_file() {
    local encrypted_file="$1"
    local decrypted_file="${encrypted_file%.encrypted}"

    echo "[DECRYPTING] $encrypted_file"

    # Use GPG to decrypt.
    echo "$PASSPHRASE" | gpg \
        --batch \
        --yes \
        --passphrase-fd 0 \
        --decrypt \
        --no-symkey-cache \
        --output "$decrypted_file" \
        "$encrypted_file" 2>/dev/null

    if [ $? -eq 0 ]; then
        # Set appropriate permissions on decrypted file.
        chmod 600 "$decrypted_file"

        # Tell git to assume the encrypted file is unchanged (so it won't show as deleted).
        git update-index --assume-unchanged "$encrypted_file" 2>/dev/null || true

        # Remove the encrypted file from working directory (it's in the repo).
        rm -f "$encrypted_file"

        echo "[SUCCESS] Decrypted: $encrypted_file -> $decrypted_file (encrypted version removed from working directory)"
        return 0
    else
        echo "[ERROR] Failed to decrypt: $encrypted_file"
        return 1
    fi
}

# Process each encrypted file.
for GPG_FILE in $GPG_FILES; do
    if decrypt_file "$GPG_FILE"; then
        DECRYPTED_COUNT=$((DECRYPTED_COUNT + 1))
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

# Summary.
echo ""
echo "========================================"
echo "Decryption Summary:"
echo "  Files decrypted: $DECRYPTED_COUNT"
echo "  Files failed: $FAILED_COUNT"
echo ""
if [ $DECRYPTED_COUNT -gt 0 ]; then
    echo "Files successfully decrypted."
    echo "Original files are in your working directory."
    echo "Encrypted versions have been removed from working directory."
fi
if [ $FAILED_COUNT -gt 0 ]; then
    echo "[WARNING] Some files failed to decrypt. Check passphrase."
fi
echo "========================================"

exit 0
