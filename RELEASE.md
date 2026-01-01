# Release Guide

This document describes how to release new versions of KeyboardLock.

## How Releases Work

1. Push a git tag like `v1.0.0` to trigger the release workflow
2. GitHub Actions builds, signs, and notarizes the app
3. A signed DMG is uploaded to GitHub Releases
4. The Sparkle appcast is updated on `gh-pages` for auto-updates

## Prerequisites

Before your first release, complete these one-time setup steps:

### 1. Add Sparkle Dependency

In Xcode:
1. File > Add Package Dependencies
2. Enter URL: `https://github.com/sparkle-project/Sparkle`
3. Select version: Up to Next Major (2.x)
4. Add to target: KeyboardLock

### 2. Generate Sparkle EdDSA Keys

```bash
# Download Sparkle tools
curl -L -o /tmp/Sparkle.dmg "https://github.com/sparkle-project/Sparkle/releases/latest/download/Sparkle-2.7.5.dmg"
hdiutil attach /tmp/Sparkle.dmg
/Volumes/Sparkle/bin/generate_keys
hdiutil detach /Volumes/Sparkle
```

This outputs:
- **Private key** → Save as `SPARKLE_PRIVATE_KEY` GitHub secret
- **Public key** → Replace `REPLACE_WITH_YOUR_PUBLIC_KEY` in `Info.plist`

### 3. Create gh-pages Branch

```bash
git checkout --orphan gh-pages
git reset --hard
echo "# KeyboardLock Releases" > README.md
git add README.md
git commit -m "chore: initial gh-pages branch"
git push origin gh-pages
git checkout main
```

### 4. Enable GitHub Pages

1. Go to repository Settings > Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` / `/ (root)`
4. Save

### 5. Configure GitHub Secrets

Go to repository Settings > Secrets and variables > Actions, then add:

| Secret | Description |
|--------|-------------|
| `DEVELOPER_ID_CERTIFICATE_BASE64` | Base64-encoded .p12 signing certificate |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password for the .p12 file |
| `APPLE_ID` | Apple ID email for notarization |
| `APPLE_ID_PASSWORD` | App-specific password (NOT your Apple ID password) |
| `APPLE_TEAM_ID` | Developer team ID: `85SNX4ZWF4` |
| `SPARKLE_PRIVATE_KEY` | EdDSA private key from step 2 |

#### How to Get Each Secret

**Developer ID Certificate:**
1. Open Keychain Access
2. Find "Developer ID Application: Your Name" in login keychain
3. Right-click > Export Item... (save as .p12 with a password)
4. Run: `base64 -i certificate.p12 | pbcopy`
5. Paste as `DEVELOPER_ID_CERTIFICATE_BASE64`
6. Set password as `DEVELOPER_ID_CERTIFICATE_PASSWORD`

**App-Specific Password:**
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign In & Security > App-Specific Passwords
3. Click + to generate a new password
4. Name it "KeyboardLock Notarization"
5. Save as `APPLE_ID_PASSWORD`

## Creating a Release

### 1. Check Latest Release

```bash
git fetch --tags --prune --prune-tags
git describe --tags --abbrev=0
```

### 2. Review Changes

```bash
# See commits since last release
git log v1.0.0..HEAD --oneline
```

### 3. Decide Version

Follow semantic versioning:
- **Patch** (v1.0.0 → v1.0.1): Bug fixes only
- **Minor** (v1.0.0 → v1.1.0): New features, backwards compatible
- **Major** (v1.0.0 → v2.0.0): Breaking changes

### 4. Create and Push Tag

**With release notes (recommended):**
```bash
cat > /tmp/release_notes.md <<'EOF'
## What's New

- Added new feature X
- Fixed bug with Y
- Improved performance of Z
EOF

git tag -a v1.0.1 -F /tmp/release_notes.md
git push origin v1.0.1
```

**Simple release:**
```bash
git tag -a v1.0.1 -m "Bug fixes and improvements"
git push origin v1.0.1
```

### 5. Monitor the Build

```bash
# Watch the workflow
gh run watch --exit-status

# Or view in browser
gh run view --web
```

### 6. Verify the Release

- **GitHub Release:** https://github.com/martin-buur/KeyboardLock/releases
- **Appcast:** https://martin-buur.github.io/KeyboardLock/appcast.xml
- **Test update:** Open an older version and click "Check for Updates..."

## Re-releasing a Version

If something went wrong:

```bash
# Delete the release and tag
gh release delete v1.0.1 --cleanup-tag --yes
git push origin --delete v1.0.1
git tag -d v1.0.1

# Create new tag and push
git tag -a v1.0.1 -m "Fixed release notes"
git push origin v1.0.1
```

## Writing Good Release Notes

Release notes appear in:
- GitHub Releases page
- Sparkle update dialog

**Guidelines:**
- Write for end users, not developers
- Focus on what users will notice
- Group related changes into single bullet points
- Omit internal changes (CI, refactoring, code cleanup)

**Example:**
```markdown
## What's New

- Lock your keyboard with a single click from the menu bar
- Added support for locking mouse input too
- Fixed issue where unlock gesture wasn't always detected
```

## Troubleshooting

### Build fails with signing error
- Verify `DEVELOPER_ID_CERTIFICATE_BASE64` is correctly base64 encoded
- Check certificate password is correct
- Ensure certificate hasn't expired

### Notarization fails
- Verify `APPLE_ID_PASSWORD` is an app-specific password, not your regular password
- Check `APPLE_TEAM_ID` matches your developer account
- Ensure your Apple Developer account is in good standing

### Appcast not updating
- Verify gh-pages branch exists and GitHub Pages is enabled
- Check that `SPARKLE_PRIVATE_KEY` is set correctly
- Look at workflow logs for generate_appcast errors

### Updates not showing in app
- Verify `SUPublicEDKey` in Info.plist matches your generated public key
- Check `SUFeedURL` points to the correct appcast.xml URL
- Try "Check for Updates..." manually from the menu
