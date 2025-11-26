#!/bin/bash
#
# Script to install Rancher CA certificate to macOS Keychain
# This allows your browser to trust the self-signed Rancher certificate
#
# Note: The certificate (rancher-ca.crt) is automatically copied to this
# directory when you run the Ansible playbook (site.yml)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="${SCRIPT_DIR}/rancher-ca.crt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║         Rancher CA Certificate Installation Script                    ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if certificate file exists
if [ ! -f "$CERT_FILE" ]; then
    echo -e "${RED}Error: Certificate file not found at $CERT_FILE${NC}"
    echo "Please run the Ansible playbook first to generate the certificate."
    exit 1
fi

echo -e "${YELLOW}Certificate file found: $CERT_FILE${NC}"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is designed for macOS only.${NC}"
    exit 1
fi

# Get certificate details from file
FILE_SERIAL=$(openssl x509 -in "$CERT_FILE" -noout -serial 2>/dev/null | cut -d= -f2)
FILE_DATES=$(openssl x509 -in "$CERT_FILE" -noout -dates 2>/dev/null)
echo -e "${BLUE}File certificate serial: ${FILE_SERIAL}${NC}"
echo ""

# Check if certificate is already in keychain and compare
KEYCHAIN_CERT=""
if security find-certificate -c "Rancher-CA" /Library/Keychains/System.keychain >/dev/null 2>&1; then
    KEYCHAIN_SERIAL=$(security find-certificate -c "Rancher-CA" -p /Library/Keychains/System.keychain 2>/dev/null | openssl x509 -noout -serial 2>/dev/null | cut -d= -f2)

    if [ "$FILE_SERIAL" = "$KEYCHAIN_SERIAL" ]; then
        echo -e "${GREEN}✓ Certificate is already installed and matches the file.${NC}"
        echo ""
        read -p "Reinstall anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "No changes made."
            exit 0
        fi
    else
        echo -e "${YELLOW}⚠ Certificate in Keychain (serial: ${KEYCHAIN_SERIAL}) differs from file!${NC}"
        echo -e "${YELLOW}  The certificate will be updated.${NC}"
        echo ""
    fi
else
    echo -e "${BLUE}No existing Rancher-CA certificate found in Keychain.${NC}"
    echo ""
fi

echo "This script will:"
echo "  1. Remove any old Rancher-CA certificates from System Keychain"
echo "  2. Add the new certificate and mark it as trusted"
echo ""
echo -e "${YELLOW}Note: You will be prompted for your admin password.${NC}"
echo ""
read -p "Do you want to continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "Adding certificate to System Keychain..."

# First, remove any old Rancher-CA certificates to avoid conflicts
echo "Removing old Rancher-CA certificates (if any)..."
while security find-certificate -c "Rancher-CA" /Library/Keychains/System.keychain >/dev/null 2>&1; do
    sudo security delete-certificate -c "Rancher-CA" /Library/Keychains/System.keychain 2>/dev/null || break
done
echo "Old certificates removed."
echo ""

# Add certificate to system keychain and mark as trusted
if sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_FILE"; then
    echo -e "${GREEN}✓ Certificate successfully added to System Keychain${NC}"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                             ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Close and reopen your browser (or restart it)"
    echo "  2. Navigate to: https://rancher.local.test"
    echo "  3. Login with:"
    echo "     Username: admin"
    echo "     Password: SuperAdmin123!"
    echo ""
    echo -e "${GREEN}You should now be able to access Rancher without certificate warnings!${NC}"
else
    echo -e "${RED}✗ Failed to add certificate to keychain${NC}"
    echo ""
    echo "Alternative method:"
    echo "  1. Open Keychain Access app"
    echo "  2. Go to File → Import Items..."
    echo "  3. Select: $CERT_FILE"
    echo "  4. Double-click the imported certificate"
    echo "  5. Expand 'Trust' section"
    echo "  6. Set 'When using this certificate' to 'Always Trust'"
    exit 1
fi
