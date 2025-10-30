# Code Signing and Notarization Guide

This guide explains how to sign and notarize ocrtool-mcp for distribution.

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

### Step 1: Create a ZIP archive

```bash
# Create a signed binary first
./scripts/sign.sh

# Create ZIP for notarization
cd .build/apple/Products/Release
zip -r ocrtool-mcp.zip ocrtool-mcp
cd -
```

### Step 2: Set environment variables

```bash
export APPLE_ID="your@email.com"
export APPLE_TEAM_ID="6X2HSWDZCR"  # Your Team ID
export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-Specific Password
```

### Step 3: Submit for notarization

```bash
./scripts/notarize.sh .build/apple/Products/Release/ocrtool-mcp.zip
```

This will:
- Upload the ZIP to Apple
- Wait for notarization to complete (usually 1-5 minutes)
- Display the result

### Step 4: Verify notarization

```bash
spctl --assess --verbose .build/apple/Products/Release/ocrtool-mcp
```

Expected output:
```
.build/apple/Products/Release/ocrtool-mcp: accepted
```

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

## References

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [notarytool Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
