#!/bin/bash
# Quick deployment script for Rancher Ansible environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Rancher Multi-Cluster Ansible Deployment - Quick Start            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Error: Ansible is not installed${NC}"
    echo "Install with: pip install ansible"
    exit 1
fi

if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: ansible-playbook is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Ansible found: $(ansible --version | head -n1)${NC}"

# Verify inventory
echo -e "${YELLOW}[2/5] Verifying inventory...${NC}"

if [ ! -f "inventory/hosts.yml" ]; then
    echo -e "${RED}Error: inventory/hosts.yml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Inventory file found${NC}"

# Test connectivity
echo -e "${YELLOW}[3/5] Testing connectivity to hosts...${NC}"

if ansible -i inventory/hosts.yml all -m ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ All hosts are reachable${NC}"
else
    echo -e "${RED}Warning: Some hosts may not be reachable${NC}"
    echo "Run 'ansible -i inventory/hosts.yml all -m ping' to check connectivity"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create shared directory
echo -e "${YELLOW}[4/5] Creating shared directory...${NC}"

SHARED_DIR="/tmp/rancher_shared"
mkdir -p "$SHARED_DIR"
chmod 755 "$SHARED_DIR"

echo -e "${GREEN}✓ Shared directory created: $SHARED_DIR${NC}"

# Run deployment
echo -e "${YELLOW}[5/5] Starting deployment...${NC}"
echo ""

# Ask for confirmation
echo -e "${YELLOW}This will deploy:${NC}"
echo "  • Rancher management cluster (local-ctrl)"
echo "  • Downstream RKE2 clusters (key-ctrl, key-worker)"
echo "  • ArgoCD (if enabled)"
echo "  • Fleet GitOps (if enabled)"
echo ""
read -p "Proceed with deployment? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Run the playbook
echo ""
echo -e "${GREEN}Starting Ansible deployment...${NC}"
echo ""

if ansible-playbook -i inventory/hosts.yml site.yml; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              🎉 Deployment Completed Successfully!                     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Access Information:${NC}"
    echo ""
    echo "🐮 Rancher UI:"
    echo "   URL: https://rancher.local.test (or your configured hostname)"
    echo "   Username: admin"
    echo "   Password: SuperAdmin123! (or your configured password)"
    echo ""
    echo "📋 Important: Import CA certificate from $SHARED_DIR/rancher-ca.crt"
    echo ""

    if [ -f "$SHARED_DIR/argocd_password" ]; then
        ARGOCD_PASS=$(cat "$SHARED_DIR/argocd_password")
        echo "🚀 ArgoCD:"
        echo "   Port-forward: kubectl port-forward -n argocd svc/argocd-server 8080:443"
        echo "   URL: https://localhost:8080"
        echo "   Username: admin"
        echo "   Password: $ARGOCD_PASS"
        echo ""
    fi

    echo "📁 Shared files location: $SHARED_DIR"
    echo ""
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    ❌ Deployment Failed                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Check the error messages above for details"
    echo "Run with verbose mode: ansible-playbook -i inventory/hosts.yml site.yml -vv"
    exit 1
fi
