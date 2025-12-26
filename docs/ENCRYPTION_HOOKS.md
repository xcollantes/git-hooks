# Git Encryption Hooks Documentation

## Summary

This repository includes secure Git hooks for automatically encrypting sensitive
files before commits and decrypting them after pull/merge operations.

## Security Features

The encryption hooks use GPG (GNU Privacy Guard) with the most secure
configuration:

- **Cipher Algorithm**: AES-256 (Advanced Encryption Standard with 256-bit key)
- **Digest Algorithm**: SHA-512 (Secure Hash Algorithm 512-bit)
- **S2K (String-to-Key)**: Mode 3 with SHA-512 digest
- **S2K Iteration Count**: 65,011,712 (maximum iterations for key derivation)
- **Compression**: ZLIB level 9
- **MDC (Modification Detection Code)**: Forced enabled for integrity checking
- **No symmetric key caching**: Ensures passphrase is always required

## Files for Hook

### Pre-commit Hook

- **Location**: `hooks/pre-commit.d/##-encrypt-files.sh`
- **Purpose**: Automatically encrypts matching files before they are committed
- **Runs**: Before every commit

### Post-merge Hook

- **Location**: `hooks/post-merge` (dispatcher)
- **Location**: `hooks/post-merge.d/##-decrypt-files.sh` (actual decryption)
- **Purpose**: Automatically decrypts encrypted files after pull/merge
  operations
- **Runs**: After `git pull` or `git merge`

## Setup Instructions

### 1. Install GPG

**macOS:**

```bash
brew install gnupg
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt-get install gnupg
```

**Linux (RedHat/CentOS):**

```bash
sudo yum install gnupg
```

### 2. Set Encryption Passphrase

On your first commit, the pre-commit hook will prompt you to create an
encryption passphrase. This passphrase will be stored in `hooks/encryption-key`
(which is git-ignored by default).

**RECOMMENDED:** Use a strong passphrase with at least 20 characters with
symbols and numbers.

## Usage

### Encrypting Files

1. Add sensitive files to your repository:

```bash
echo "API_KEY=secret123" > config.secret
git add config.secret
```

2. Commit as usual:

```bash
git commit -m "Add configuration"
```

3. The pre-commit hook will:
   - Encrypt the files with GPG using AES-256
   - Stage the encrypted `.gpg` files
   - Unstage the original files (they remain in your working directory)

### Decrypting Files

When you pull changes:

```bash
git pull
```

The post-merge hook will:

- Automatically detect `.gpg` files
- Decrypt them using your passphrase
- Save decrypted files to your working directory

## Security Best Practices

1. **Never commit** the `.git/encryption-key` file
2. **Share the passphrase securely** with team members (use password managers or
   secure channels)
3. **Use a strong passphrase** (minimum 20 characters, mix of letters, numbers,
   symbols)
4. **Rotate the passphrase periodically** for sensitive projects
5. **Keep GPG updated** to the latest version
6. **Backup your encryption key** securely

## Pitfalls

### "GPG is not installed"

Install GPG using the instructions in the Setup section.

### "Failed to decrypt"

Check that your passphrase in `.git/encryption-key` matches the one used to
encrypt files.

### "No encryption key file found"

The pre-commit hook will create one on first run. For decryption, you need to
create it manually with the correct passphrase.

### Files not encrypting

Check that your files match the patterns in `DEFAULT_ENCRYPT_PATTERNS` or your
custom `.git/encrypt-config`.
