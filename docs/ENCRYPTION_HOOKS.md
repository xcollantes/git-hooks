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

### 3. Configure Files to Encrypt (Optional)

By default, the following patterns are encrypted:

- `*.secret`
- `*.private`
- `*.key`
- `secrets/*`
- `private/*`

To customize, create `.git/encrypt-config`:

```bash
# Custom encryption patterns.
CUSTOM_ENCRYPT_PATTERNS=(
    '*.secret'
    '*.private'
    'config/production.yml'
    'keys/*'
)
```

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
   - Detect files matching encryption patterns
   - Encrypt them with GPG using AES-256
   - Stage the encrypted `.gpg` files
   - Unstage the original files (they remain in your working directory)

### Decrypting Files

When you pull changes containing encrypted files:

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

## Team Collaboration

### For New Team Members:

1. Install GPG (see Setup Instructions)
2. Get the encryption passphrase from your team lead (through secure channel)
3. Create `.git/encryption-key` file:

```bash
echo "your-passphrase-here" > .git/encryption-key
chmod 600 .git/encryption-key
```

4. Pull the repository:

```bash
git pull
```

Files will automatically decrypt.

### For Existing Team Members:

No changes needed. The hooks work automatically once configured.

## Troubleshooting

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

## Technical Details

### Encryption Process

1. File is read from staging area
2. GPG encrypts using symmetric AES-256 with maximum S2K iterations
3. Encrypted file (`.gpg` extension) is staged
4. Original file is unstaged (remains in working directory)

### Decryption Process

1. After merge/pull, hook scans for `.gpg` files
2. GPG decrypts using the stored passphrase
3. Decrypted files are written to working directory
4. Permissions are set to 600 (owner read/write only)

### Key Derivation

The S2K (String-to-Key) process uses 65,011,712 iterations of SHA-512, making
passphrase brute-forcing computationally expensive.

## Limitations

- **Performance**: Due to maximum security settings, encryption/decryption is
  slower than default GPG settings
- **Binary Files**: Works with all file types including binary
- **Large Files**: Very large files will take longer to encrypt/decrypt
- **Git LFS**: Not optimized for use with Git LFS

## Alternative: Manual Encryption

If you prefer manual control, you can encrypt/decrypt manually:

**Encrypt:**

```bash
echo "passphrase" | gpg --batch --yes --passphrase-fd 0 --symmetric \
  --cipher-algo AES256 --digest-algo SHA512 --s2k-count 65011712 \
  --output file.gpg file.txt
```

**Decrypt:**

```bash
echo "passphrase" | gpg --batch --yes --passphrase-fd 0 --decrypt \
  --output file.txt file.gpg
```

## License

These hooks are provided as-is for use in your projects.
