# Git Encryption Hooks Documentation

These hooks for encrypt and decrypt files using GPG may be non-intuitive. When
you commit a file, the original file is kept in your working directory, but the
encrypted version is committed to the repository. When you pull, merge, clone,
or checkout, the encrypted files are decrypted and the original files are kept
in your working directory.

## Summary

This repository includes secure Git hooks for automatically encrypting sensitive
files before commits and decrypting them after pull/merge/checkout operations.

**How it works:**

- **Committing**: Original files stay in your working directory (not committed).
  Encrypted versions are committed to the repository but NOT kept in your local
  directory.
- **Pulling/Merging/Cloning**: Encrypted files are automatically decrypted to
  your working directory. The encrypted versions are removed from your local
  directory.

**NOTE**: The hooks will all run as long as they are in the `.git/hooks`
directory. To exclude a hook, remove it to the `hooks` directory. To skip all
hooks, use `git commit --no-verify -m "COMMIT MESSAGE"` flag.

## Quick Reference

| Location                   | Original Files           | Encrypted Files           |
| -------------------------- | ------------------------ | ------------------------- |
| **Your Working Directory** | ✅ Present (unencrypted) | ❌ Not present            |
| **Git Repository**         | ❌ Not present           | ✅ Present (`.encrypted`) |
| **GitHub/GitLab**          | ❌ Not visible           | ✅ Visible (`.encrypted`) |

**In short**: You work with original files locally. The repository stores
encrypted files.

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

- **Location**: `hooks/pre-commit` (dispatcher)
- **Location**: `hooks/pre-commit.d/02-encrypt-files.sh` (actual encryption)
- **Purpose**: Automatically encrypts matching files before they are committed
- **Runs**: Before every commit
- **Behavior**:
  - Encrypts files and commits the encrypted versions to the repository
  - Keeps original files in your working directory (not committed)
  - Does NOT keep encrypted files in your working directory

### Post-merge Hook

- **Location**: `hooks/post-merge` (dispatcher)
- **Location**: `hooks/post-merge.d/01-decrypt-files.sh` (actual decryption)
- **Purpose**: Automatically decrypts encrypted files after pull/merge
  operations
- **Runs**: After `git pull` or `git merge`
- **Behavior**:
  - Decrypts `.encrypted` files to original files
  - Removes encrypted files from your working directory

### Post-checkout Hook

- **Location**: `hooks/post-checkout` (dispatcher)
- **Location**: `hooks/post-checkout.d/01-decrypt-files.sh` (actual decryption)
- **Purpose**: Automatically decrypts encrypted files after clone/checkout
  operations
- **Runs**: After `git clone` or `git checkout` (branch switching)
- **Behavior**:
  - Decrypts `.encrypted` files to original files
  - Removes encrypted files from your working directory

## File Patterns

The following file patterns are automatically encrypted when committed (defined
in `hooks/pre-commit.d/02-encrypt-files.sh`):

- Text files: `*.txt`, `*.md`
- Scripts: `*.sh`, `*.py`, `*.js`
- Configuration: `*.json`, `*.yaml`, `*.yml`, `*.xml`
- Web files: `*.html`, `*.css`
- Documents: `*.pdf`, `*.doc`, `*.docx`, `*.odt`
- Spreadsheets: `*.xls`, `*.xlsx`, `*.csv`, `*.tsv`, `*.ods`
- Presentations: `*.ppt`, `*.pptx`
- Database: `*.sql`, `*.db`, `*.sqlite`, `*.sqlite3`
- Images: `*.jpg`, `*.jpeg`, `*.png`, `*.gif`, `*.ico`, `*.webp`, `*.svg`
- Media: `*.mp3`, `*.mp4`

To customize which files are encrypted, edit the `ENCRYPT_FILENAME_PATTERNS`
array in `hooks/pre-commit.d/02-encrypt-files.sh`.

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

### 2. Install Hooks

Copy the hook files to your repository's `.git/hooks` directory:

```bash
# Copy all hooks
cp hooks/pre-commit .git/hooks/
cp hooks/post-merge .git/hooks/
cp hooks/post-checkout .git/hooks/

# Copy hook directories
cp -r hooks/pre-commit.d .git/hooks/
cp -r hooks/post-merge.d .git/hooks/
cp -r hooks/post-checkout.d .git/hooks/

# Make hooks executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/post-merge
chmod +x .git/hooks/post-checkout
chmod +x .git/hooks/pre-commit.d/*
chmod +x .git/hooks/post-merge.d/*
chmod +x .git/hooks/post-checkout.d/*
```

### 3. Set Encryption Passphrase

On your first commit, the pre-commit hook will prompt you to create an
encryption passphrase. This passphrase will be stored in `.git/encryption-key`
(which is git-ignored by default).

**RECOMMENDED:** Use a strong passphrase with at least 20 characters with
symbols and numbers.

**For team members cloning the repository**: They will need to create the
`.git/encryption-key` file manually with the shared passphrase, or they will be
prompted on first pull/checkout.

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
   - Commit the encrypted `.encrypted` files to the repository
   - Keep the original files in your working directory (not committed)
   - Remove the encrypted files from your working directory

**Result**: Your repository contains `config.secret.encrypted`, but your working
directory only has `config.secret` (the original unencrypted file).

### Decrypting Files

When you pull, merge, clone, or checkout:

```bash
git pull
# or
git clone <repository-url>
# or
git checkout <branch>
```

The post-merge or post-checkout hook will:

- Automatically detect `.encrypted` files from the repository
- Decrypt them using your passphrase
- Save decrypted original files to your working directory
- Remove the encrypted files from your working directory

**Result**: Your working directory contains the original unencrypted files, not
the `.encrypted` versions.

### What You'll See in Different Commands

**git status** (after commit):

- Shows no changes for encrypted files (they're marked as --assume-unchanged)
- Shows your original files as untracked (if you haven't added them to
  .gitignore)

**git log --stat** or **git show**:

- Shows changes to `.encrypted` files, not the original files

**Browsing on GitHub/GitLab**:

- You'll see only `.encrypted` files in the repository
- They appear as binary blobs (not human-readable)

**git diff**:

- For staged files: shows diff of your original files (before encryption)
- For committed files: shows diff of `.encrypted` files (not very useful)

## Important: .gitignore Configuration

Add your original sensitive files to `.gitignore` to prevent accidentally
committing them:

```gitignore
# Sensitive files (only encrypted versions should be in repo)
*.secret
api-keys.txt
database.config
.env
.env.local

# Encryption key (NEVER commit this)
.git/encryption-key
```

**Note**: The hooks will still encrypt these files when you explicitly `git add`
them, but `.gitignore` provides an extra safety net.

## Security Best Practices

1. **Never commit** the `.git/encryption-key` file
2. **Add original sensitive files to .gitignore** as a safety net
3. **Share the passphrase securely** with team members (use password managers or
   secure channels)
4. **Use a strong passphrase** (minimum 20 characters, mix of letters, numbers,
   symbols)
5. **Rotate the passphrase periodically** for sensitive projects
6. **Keep GPG updated** to the latest version
7. **Backup your encryption key** securely
8. **Verify encrypted files** by checking that only `.encrypted` versions are in
   the repository

## Workflow Diagram

### Commit Flow

```
1. You edit: config.secret (in working directory)
2. git add config.secret
3. git commit
   |
   +--> Pre-commit hook runs:
        - Creates config.secret.encrypted (GPG encrypted)
        - Stages config.secret.encrypted for commit
        - Unstages config.secret (keeps in working directory)
        - Deletes config.secret.encrypted from working directory
   |
4. Repository now contains: config.secret.encrypted
5. Your working directory still has: config.secret (original)
```

### Pull/Merge/Clone Flow

```
1. git pull (or git clone, git merge, git checkout)
   |
   +--> Git fetches: config.secret.encrypted
   |
2. Post-merge or Post-checkout hook runs:
   - Finds config.secret.encrypted in working directory
   - Decrypts it to config.secret
   - Deletes config.secret.encrypted from working directory
   |
3. Your working directory now has: config.secret (original)
4. Repository still contains: config.secret.encrypted
```

## How Files Are Stored

### In the Repository (Git)

The repository contains **only encrypted files** with the `.encrypted`
extension:

- `config.secret.encrypted`
- `api-keys.txt.encrypted`
- `database.config.encrypted`

### In Your Working Directory (Local)

Your working directory contains **only the original unencrypted files**:

- `config.secret`
- `api-keys.txt`
- `database.config`

The encrypted `.encrypted` files are **never kept** in your working directory
after commit or after decryption.

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

Check that your files match the patterns in the `ENCRYPT_FILENAME_PATTERNS`
array in `hooks/pre-commit.d/02-encrypt-files.sh`.

### Git shows encrypted files as deleted

This is normal. The hooks use `git update-index --assume-unchanged` to tell git
to ignore the absence of the encrypted files in the working directory. The files
still exist in the repository.

### Cloning doesn't decrypt files

Make sure the `post-checkout` hook is installed in `.git/hooks/` and is
executable. This hook is responsible for decrypting files after a clone
operation.
