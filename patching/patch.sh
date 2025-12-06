#!/bin/bash
# Simple patching script for Rancher and RKE2

set -e

# Change to ansible root directory (parent of patching/)
cd "$(dirname "$0")/.."

INVENTORY="inventory/hosts.yml"
PATCHING_DIR="patching"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Rancher and RKE2 Upgrade Script                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Show target versions
echo "📋 Target versions:"
echo "  RKE2:         $(grep "^rke2_version:" $PATCHING_DIR/patch-versions.yml | awk '{print $2}' | tr -d '"')"
echo "  Rancher:      $(grep "^rancher_version:" $PATCHING_DIR/patch-versions.yml | awk '{print $2}' | tr -d '"')"
echo "  cert-manager: $(grep "^cert_manager_version:" $PATCHING_DIR/patch-versions.yml | awk '{print $2}' | tr -d '"')"
echo ""

read -p "Continue with upgrade? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Step 1/4: Creating backups..."
ansible-playbook -i $INVENTORY $PATCHING_DIR/backup.yml

echo ""
echo "Step 2/4: Upgrading RKE2 on management cluster..."
ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rke2.yml --limit management

echo ""
echo "Step 3/4: Upgrading Rancher..."
ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rancher.yml

echo ""
echo "Step 4/4: Upgrading RKE2 on downstream clusters..."
ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rke2.yml --limit downstream_clusters

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         ✅ Upgrade Complete!                                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  - Test Rancher UI: https://rancher.local.test"
echo "  - Verify clusters in Rancher"
echo "  - Test your applications"
echo ""
