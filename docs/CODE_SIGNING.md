# Code Signing and Notarization Guide

This guide explains how to sign and notarize ocrtool-mcp for distribution.

## Quick Start

For a complete automated build, sign, and notarize workflow:

```bash
# One command to rule them all
./scripts/build-release.sh 1.0.1

# This will:
# 1. Build universal binary
# 2. Sign with your Developer ID
# 3. Create release archives
# 4. Generate checksums
# 5. Optionally notarize
```

---

## Prerequisites

### 1. Apple Developer Account

You need an active Apple Developer account ($99/year) to:
- Get a Developer ID Application certificate
- Notarize your app

### 2. Developer ID Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates)
2. Create a "Developer ID Application" certificate
3. Download and install it in Keychain Access

### 3. App-Specific Password (for notarization)

1. Go to [Apple ID Account](https://appleid.apple.com/account/manage)
2. Under "Sign-In and Security", generate an App-Specific Password
3. Save it securely (you'll need it for notarization)

---

## Code Signing

### Automatic Signing (Recommended)

Use the provided script:

```bash
# Sign the release binary
./scripts/sign.sh

# Or specify a custom path
./scripts/sign.sh /path/to/ocrtool-mcp
```

### Manual Signing

```bash
codesign --sign "Developer ID Application: Your Name (TEAMID)" \
    --options runtime \
    --timestamp \
    --force \
    .build/apple/Products/Release/ocrtool-mcp

# Verify
codesign --verify --verbose .build/apple/Products/Release/ocrtool-mcp
```

---

## Notarization

Notarization removes the "unidentified developer" warning on macOS.

### Method 1: Using Keychain Profile (Recommended)

This is the most secure and convenient method - no need to expose passwords in scripts.

#### Setup Keychain Profile (One-time)

```bash
# Store credentials securely in Keychain
xcrun notarytool store-credentials "AC_PASSWORD" \
    --apple-id "your@email.com" \
    --team-id "6X2HSWDZCR" \
    --password "xxxx-xxxx-xxxx-xxxx"

# Verify profile was created
xcrun notarytool list-profiles
```

#### Notarize Using Profile

```bash
# Create a signed binary first
./scripts/sign.sh

# Create ZIP for notarization
cd .build/apple/Products/Release
zip -r ocrtool-mcp.zip ocrtool-mcp
cd -

# Submit using keychain profile
xcrun notarytool submit .build/apple/Products/Release/ocrtool-mcp.zip \
    --keychain-profile "AC_PASSWORD" \
    --wait

# Verify notarization
spctl --assess --verbose .build/apple/Products/Release/ocrtool-mcp
```

### Method 2: Using Environment Variables

For CI/CD environments or automated workflows.

#### Step 1: Create a ZIP archive

```bash
# Create a signed binary first
./scripts/sign.sh

# Create ZIP for notarization
cd .build/apple/Products/Release
zip -r ocrtool-mcp.zip ocrtool-mcp
cd -
```

#### Step 2: Set environment variables

```bash
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="6X2HSWDZCR"  # Your Team ID
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-Specific Password
```

#### Step 3: Submit for notarization

```bash
./scripts/notarize.sh .build/apple/Products/Release/ocrtool-mcp.zip
```

This will:
- Upload the ZIP to Apple
- Wait for notarization to complete (usually 1-5 minutes)
- Display the result

#### Step 4: Verify notarization

```bash
spctl --assess --verbose .build/apple/Products/Release/ocrtool-mcp
```

Expected output:
```
.build/apple/Products/Release/ocrtool-mcp: accepted
```

### Stapling Notarization Ticket

For DMG or App bundles, you can "staple" the notarization ticket so it works offline:

```bash
# After successful notarization
xcrun stapler staple YourApp.dmg
# or
xcrun stapler staple YourApp.app

# Verify stapling
xcrun stapler validate YourApp.dmg
```

**Note**: For simple executables like ocrtool-mcp, stapling is not necessary.

---

## GitHub Actions Integration

To enable automatic signing in GitHub Actions, add these secrets to your repository:

1. Go to Repository Settings → Secrets → Actions
2. Add the following secrets:
   - `APPLE_CERTIFICATE_BASE64`: Base64-encoded P12 certificate
   - `APPLE_CERTIFICATE_PASSWORD`: P12 password
   - `APPLE_ID`: Your Apple ID email
   - `APPLE_TEAM_ID`: Your Team ID
   - `APPLE_APP_PASSWORD`: App-Specific Password

### Export Certificate as Base64

```bash
# Export certificate from Keychain
security find-identity -v -p codesigning

# Export as P12 (you'll be prompted for a password)
security export -t identities -f pkcs12 \
    -P "your-password" \
    -o certificate.p12

# Convert to base64
base64 -i certificate.p12 -o certificate.base64.txt

# Copy the contents of certificate.base64.txt to GitHub Secrets
```

### Update GitHub Actions Workflow

Add signing step to `.github/workflows/release.yml`:

```yaml
- name: Import Certificate
  env:
    CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
    CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD  }}
  run: |
    echo $CERTIFICATE_BASE64 | base64 --decode > certificate.p12
    security create-keychain -p actions build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p actions build.keychain
    security import certificate.p12 -k build.keychain \
      -P $CERTIFICATE_PASSWORD -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: \
      -s -k actions build.keychain

- name: Sign binary
  run: ./scripts/sign.sh

- name: Notarize
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
    APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
  run: |
    cd .build/apple/Products/Release
    zip -r ocrtool-mcp.zip ocrtool-mcp
    cd -
    ./scripts/notarize.sh .build/apple/Products/Release/ocrtool-mcp.zip
```

---

## Troubleshooting

### "Developer cannot be verified" warning

This means the app is not notarized. Users can bypass this by:
1. Right-click the app → Open
2. Or: System Settings → Privacy & Security → Allow

### Signature verification fails

```bash
# Check if certificate is installed
security find-identity -v -p codesigning

# Verify binary signature
codesign --verify --deep --strict --verbose=2 <binary>

# Check what's signed
codesign -dvvv <binary>
```

### Notarization fails

Common issues:
- Binary not signed with "runtime" hardening
- Certificate expired
- Wrong App-Specific Password
- Team ID mismatch

Check notarization log:
```bash
xcrun notarytool log <submission-id> \
    --apple-id your@email.com \
    --team-id TEAMID \
    --password xxxx-xxxx-xxxx-xxxx
```

---

## Complete Release Workflow

Here's the recommended workflow for creating a new release with signing and notarization.

### One-Time Setup

1. **Install Developer ID Certificate** (see Prerequisites section above)

2. **Setup Keychain Profile** (recommended):
   ```bash
   xcrun notarytool store-credentials "AC_PASSWORD" \
       --apple-id "your@email.com" \
       --team-id "6X2HSWDZCR" \
       --password "xxxx-xxxx-xxxx-xxxx"
   ```

### For Each Release

#### Option 1: Automated Script (Recommended)

```bash
# Build, sign, and optionally notarize
./scripts/build-release.sh 1.0.1

# The script will prompt you to notarize
# Output will be in release/ directory
```

#### Option 2: Manual Steps

```bash
# 1. Build
swift build -c release --arch arm64 --arch x86_64

# 2. Sign
./scripts/sign.sh

# 3. Package
cd .build/apple/Products/Release
tar -czf ocrtool-mcp-v1.0.1-universal-macos.tar.gz ocrtool-mcp
zip -r ocrtool-mcp.zip ocrtool-mcp

# 4. Notarize
cd -
./scripts/notarize.sh .build/apple/Products/Release/ocrtool-mcp.zip AC_PASSWORD

# 5. Verify
spctl --assess --verbose .build/apple/Products/Release/ocrtool-mcp

# 6. Generate checksums
cd .build/apple/Products/Release
shasum -a 256 ocrtool-mcp ocrtool-mcp-v1.0.1-universal-macos.tar.gz
```

### Publishing to GitHub

```bash
# Create and push tag
git tag v1.0.1
git push origin v1.0.1

# GitHub Actions will automatically build and create release
# Or manually create release:
gh release create v1.0.1 \
    release/ocrtool-mcp-v1.0.1-universal-macos.tar.gz \
    release/checksums.txt \
    --title "v1.0.1 Release" \
    --notes "See CHANGELOG.md for details"
```

### Updating Homebrew Formula

After publishing a new release:

```bash
# 1. Get SHA256 of the new release
curl -sL https://github.com/ihugang/ocrtool-mcp/archive/refs/tags/v1.0.1.tar.gz | shasum -a 256

# 2. Update Formula/ocrtool-mcp.rb:
#    - Update version number
#    - Update sha256 hash

# 3. Commit and push to homebrew-ocrtool repository
cd /opt/homebrew/Library/Taps/ihugang/homebrew-ocrtool
git add Formula/ocrtool-mcp.rb
git commit -m "Update ocrtool-mcp to v1.0.1"
git push

# 4. Test the update
brew upgrade ocrtool-mcp
```

---

## Best Practices

### Security

- ✅ **Use keychain profiles** instead of exposing passwords in scripts
- ✅ **Enable hardened runtime** for better security (`--options runtime`)
- ✅ **Use timestamps** to ensure long-term signature validity
- ✅ **Verify signatures** after signing (`codesign --verify`)
- ✅ **Test on a clean system** before distributing

### Automation

- ✅ **Use build scripts** to ensure consistency
- ✅ **Automate with GitHub Actions** for releases
- ✅ **Generate checksums** for verification
- ✅ **Keep credentials in GitHub Secrets** for CI/CD

### Distribution

- ✅ **Always notarize** for public distribution
- ✅ **Provide multiple installation methods** (Homebrew, direct download)
- ✅ **Include clear installation instructions**
- ✅ **Document system requirements**

---

## References

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [notarytool Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
