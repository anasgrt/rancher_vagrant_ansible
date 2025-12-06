#!/bin/bash
# Reset script for Rancher Ansible environment (VMs remain intact)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║     Rancher Ansible Configuration - RESET                             ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This will remove all Ansible-deployed configurations (Rancher, RKE2, etc.)${NC}"
echo -e "${YELLOW}Vagrant VMs will remain running but will be cleaned.${NC}"
echo ""
read -n1 -p "Are you sure you want to continue? (type 'y' to confirm): " -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Aborted. No changes made.${NC}"
    exit 0
fi

echo -e "${BLUE}[1/2] Running Ansible reset playbook...${NC}"
if [ -f "reset.yml" ]; then
    ansible-playbook -i inventory/hosts.yml reset.yml
else
    echo -e "${RED}Error: reset.yml not found${NC}"
    exit 1
fi

echo -e "${BLUE}[2/2] Cleaning up local artifacts...${NC}"
rm -rf /tmp/rancher_shared 2>/dev/null || true
rm -f vagrant-ssh-config 2>/dev/null || true

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Ansible configuration reset successfully!                          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Vagrant VMs are still running.${NC}"
echo -e "${YELLOW}To redeploy Ansible configurations, run:${NC}"
echo -e "  ${BLUE}./deploy.sh${NC}"
echo ""
echo -e "${YELLOW}To destroy VMs as well, run:${NC}"
echo -e "  ${BLUE}vagrant destroy -f${NC}"
echo ""
