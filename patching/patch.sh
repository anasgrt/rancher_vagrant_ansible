#!/bin/bash
# Simple patching script for Rancher and RKE2

set -e

# Change to ansible root directory (parent of patching/)
cd "$(dirname "$0")/.."

INVENTORY="inventory/hosts.yml"
PATCHING_DIR="patching"

# Parse versions from patch-versions.yml
get_version() {
    grep "^$1:" $PATCHING_DIR/patch-versions.yml | awk '{print $2}' | tr -d '"'
}

RKE2_VERSION=$(get_version "rke2_version")
RANCHER_VERSION=$(get_version "rancher_version")
CERT_MANAGER_VERSION=$(get_version "cert_manager_version")
KARGO_VERSION=$(get_version "kargo_version")
ARGOCD_VERSION=$(get_version "argocd_version")
PROMETHEUS_VERSION=$(get_version "prometheus_version")
NGINX_INGRESS_VERSION=$(get_version "nginx_ingress_version")

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Rancher and RKE2 Upgrade Script                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Show target versions
echo "📋 Target versions:"
echo "  RKE2:           $RKE2_VERSION"
echo "  Rancher:        $RANCHER_VERSION"
echo "  cert-manager:   $CERT_MANAGER_VERSION"
echo ""
echo "📋 Fleet component versions:"
echo "  Kargo:          $KARGO_VERSION"
echo "  ArgoCD:         $ARGOCD_VERSION"
echo "  Prometheus:     $PROMETHEUS_VERSION"
echo "  nginx-ingress:  $NGINX_INGRESS_VERSION"
echo ""

read -p "Continue with upgrade? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Step 1/8: Creating backups..."
ansible-playbook -i $INVENTORY $PATCHING_DIR/backup.yml

echo ""
echo "Step 2/8: Upgrading RKE2 on management cluster..."
RKE2_MGMT_UPDATED=""
RKE2_MGMT_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rke2.yml --limit management 2>&1)
echo "$RKE2_MGMT_OUTPUT"
if echo "$RKE2_MGMT_OUTPUT" | grep -q "upgraded to"; then
    RKE2_MGMT_UPDATED="✓ updated"
fi

echo ""
echo "Step 3/8: Upgrading Rancher..."
RANCHER_UPDATED=""
RANCHER_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rancher.yml 2>&1)
echo "$RANCHER_OUTPUT"
if echo "$RANCHER_OUTPUT" | grep -q "upgraded to"; then
    RANCHER_UPDATED="✓ updated"
fi

echo ""
echo "Step 4/8: Upgrading RKE2 on downstream clusters..."
RKE2_DOWN_UPDATED=""
RKE2_DOWN_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-rke2.yml --limit downstream_clusters 2>&1)
echo "$RKE2_DOWN_OUTPUT"
if echo "$RKE2_DOWN_OUTPUT" | grep -q "upgraded to"; then
    RKE2_DOWN_UPDATED="✓ updated"
fi
RKE2_UPDATED="${RKE2_MGMT_UPDATED}${RKE2_DOWN_UPDATED}"
[[ -n "$RKE2_UPDATED" ]] && RKE2_UPDATED="✓ updated"

echo ""
echo "Step 5/8: Upgrading Kargo..."
KARGO_UPDATED=""
KARGO_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-kargo.yml 2>&1)
echo "$KARGO_OUTPUT"
if echo "$KARGO_OUTPUT" | grep -q "upgraded:"; then
    KARGO_UPDATED="✓ updated"
fi

echo ""
echo "Step 6/8: Upgrading ArgoCD..."
ARGOCD_UPDATED=""
ARGOCD_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-argocd.yml 2>&1)
echo "$ARGOCD_OUTPUT"
if echo "$ARGOCD_OUTPUT" | grep -q "upgraded"; then
    ARGOCD_UPDATED="✓ updated"
fi

echo ""
echo "Step 7/8: Upgrading Prometheus..."
PROMETHEUS_UPDATED=""
PROMETHEUS_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-prometheus.yml 2>&1)
echo "$PROMETHEUS_OUTPUT"
if echo "$PROMETHEUS_OUTPUT" | grep -q "upgraded:"; then
    PROMETHEUS_UPDATED="✓ updated"
fi

echo ""
echo "Step 8/8: Upgrading nginx-ingress..."
NGINX_UPDATED=""
NGINX_OUTPUT=$(ansible-playbook -i $INVENTORY $PATCHING_DIR/upgrade-nginx-ingress.yml 2>&1)
echo "$NGINX_OUTPUT"
if echo "$NGINX_OUTPUT" | grep -q "upgraded:"; then
    NGINX_UPDATED="✓ updated"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Upgrade Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "  %-18s %-22s %s\n" "Component" "Version" "Status"
echo "  ─────────────────────────────────────────────────────────────"
printf "  %-18s %-22s %s\n" "RKE2" "$RKE2_VERSION" "$RKE2_UPDATED"
printf "  %-18s %-22s %s\n" "Rancher" "$RANCHER_VERSION" "$RANCHER_UPDATED"
printf "  %-18s %-22s %s\n" "cert-manager" "$CERT_MANAGER_VERSION" ""
printf "  %-18s %-22s %s\n" "Kargo" "$KARGO_VERSION" "$KARGO_UPDATED"
printf "  %-18s %-22s %s\n" "ArgoCD" "$ARGOCD_VERSION" "$ARGOCD_UPDATED"
printf "  %-18s %-22s %s\n" "Prometheus" "$PROMETHEUS_VERSION" "$PROMETHEUS_UPDATED"
printf "  %-18s %-22s %s\n" "nginx-ingress" "$NGINX_INGRESS_VERSION" "$NGINX_UPDATED"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  - Test Rancher UI: https://rancher.local.test"
echo "  - Verify clusters in Rancher"
echo "  - Test your applications"
echo ""
