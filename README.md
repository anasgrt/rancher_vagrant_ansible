# Rancher Multi-Cluster with Fleet, Kargo & ArgoCD

Automated deployment of a Rancher multi-cluster environment with GitOps workflow using Fleet, Kargo for progressive delivery, and ArgoCD for continuous deployment. Can be deployed via Vagrant (local VMs) or any SSH-accessible hosts.

## Quick Start

### Option 1: Vagrant (Local Development)
```bash
# Uses included Vagrantfile to provision VMs
vagrant up
```

### Option 2: Existing Infrastructure
```bash
# 1. Edit inventory with your host IPs
vim inventory/hosts.yml

# 2. Customize settings (optional)
vim group_vars/all.yml

# 3. Test connectivity
ansible -i inventory/hosts.yml all -m ping

# 4. Deploy
./deploy.sh
```

## What Gets Deployed

### Management Cluster (local-ctrl)
- **RKE2** v1.31.3 with Calico CNI
- **Rancher** (latest) with cert-manager
- **Fleet GitOps** (via Rancher) managing two GitRepos:
  - `local-manifests`: Deploys to management cluster (Kargo, ArgoCD, monitoring)
  - `key-manifests`: Deploys to downstream key clusters
- **Kargo** v1.1.0 (via Fleet): Progressive delivery controller
- **ArgoCD** (via Fleet): Continuous deployment to Kargo-managed stages

### Downstream Cluster (key)
- **RKE2** control plane + worker nodes
- **Rancher agents** connecting to management cluster
- **Fleet-managed workloads** deployed to key/gitrepos/{common,acc,prd}

### GitOps Workflow
1. Fleet monitors Git repositories for manifest changes
2. Kargo watches container registries for new images
3. Kargo promotes changes through stages (acc → prd)
4. ArgoCD syncs applications to each Kargo stage namespace

## Configuration

### Inventory (`inventory/hosts.yml`)
Set your host IPs:
```yaml
management:
  hosts:
    local-ctrl:
      ansible_host: 192.168.56.10  # Change to your IP
```

### Variables (`group_vars/all.yml`)

Key settings:

- `rancher_hostname`: Rancher URL hostname
- `rancher_bootstrap_password`: Admin password
- `rke2_version`: RKE2 version
- `cni`: Network plugin (canal/cilium/calico)
- `argocd_enabled`: Enable ArgoCD deployment
- `argocd_kargo_apps`: ArgoCD applications for Kargo stages (key01-acc, key01-prd, key02-acc, key02-prd)
- `kargo_enabled`: Enable Kargo progressive delivery
- `kargo_git_repo_url`: Git repo for Kargo to monitor
- `fleet_enabled`: Enable Fleet GitOps
- `fleet_key_git_repo_url`: Fleet GitRepo for key cluster workloads
- `fleet_local_git_repo_url`: Fleet GitRepo for management cluster (Kargo, ArgoCD, monitoring)

## Access

After deployment:

**Rancher UI:**

- URL: `https://rancher.local.test` (or your configured hostname)
- Username: `admin`
- Password: `SuperAdmin123!` (or configured)
- **Note**: CA certificate is automatically installed to macOS Keychain during playbook execution (requires passwordless sudo). If automatic installation fails, follow the instructions displayed in the playbook output.

**ArgoCD** (deployed via Fleet):

- URL: `https://argocd.192.168.56.10.nip.io` (or `argocd.<management-ip>.nip.io` for custom IPs)
- Credentials displayed at the end of playbook execution
- Uses nip.io for automatic DNS resolution

**Kargo** (deployed via Fleet):

- URL: `https://kargo.192.168.56.10.nip.io` (or `kargo.<management-ip>.nip.io` for custom IPs)
- Credentials displayed at the end of playbook execution
- Uses nip.io for automatic DNS resolution

**Note**: After running the Ansible playbook, access URLs and credentials for both ArgoCD and Kargo will be displayed in the output.

## Shared Files

Files are shared via `.shared/` directory (in the Ansible project root):

- `rancher-ca.crt` - CA certificate
- `rancher_token` - API token
- `kubeconfig-*` - Cluster configs
- `node-token*` - Join tokens
- `cluster_*_import.yml` - Cluster import information

## Troubleshooting

```bash
# Check connectivity
ansible -i inventory/hosts.yml all -m ping

# Verbose output
ansible-playbook -i inventory/hosts.yml site.yml -vv

# Check shared files
ls -la .shared/

# Check Fleet GitRepos
kubectl get gitrepos -n fleet-default

# Check Kargo stages and promotions
kubectl get stages,freights,promotions -n kargo

# Check ArgoCD applications
kubectl get applications -n argocd

# SSH to hosts
ssh ubuntu@192.168.56.10
```

## Structure

```text
ansible/
├── Vagrantfile              # Local VM provisioning (optional)
├── site.yml                 # Main playbook
├── deploy.sh                # Deployment wrapper script
├── install-cert.sh          # CA certificate installer (macOS)
├── inventory/hosts.yml      # Host definitions
├── group_vars/all.yml       # Configuration
└── roles/                   # 11 deployment roles
    ├── system_setup         # DNS, packages, hostname
    ├── rke2_server          # RKE2 management cluster
    ├── rke2_common          # Common RKE2 configuration
    ├── rke2_post_install    # Post-installation tasks
    ├── rancher_server       # Rancher + cert-manager
    ├── rke2_downstream_control   # Downstream control plane
    ├── rancher_agent_control     # Rancher agent for control plane
    ├── rke2_downstream_worker    # Downstream worker nodes
    ├── rancher_agent_worker      # Rancher agent for workers
    ├── argocd               # ArgoCD configuration (deprecated - now via Fleet)
    └── gitops_setup          # GitOps configuration (Fleet, ArgoCD, Kargo)
```

## GitOps Repository Structure

The Fleet GitRepos reference: `https://github.com/anasgrt/rancher-fleet-test.git`

```text
rancher-fleet-test/
├── local/gitrepos/          # Management cluster workloads
│   ├── argocd/              # ArgoCD deployment
│   ├── kargo-helm/          # Kargo Helm chart
│   ├── kargo-namespace/     # Kargo namespace and project
│   ├── kargo-resources/     # Kargo stages, warehouses, RBAC
│   └── monitoring/          # Prometheus/monitoring
└── key/gitrepos/            # Downstream key cluster workloads
    ├── common/              # Shared workloads (nginx-ingress)
    ├── acc/                 # Acceptance environment
    └── prd/                 # Production environment
```

## Notes

- Playbooks are idempotent (safe to re-run)
- ArgoCD and Kargo are deployed via Fleet GitOps, not directly by Ansible
- Fleet manages two separate GitRepos (local-manifests for management, key-manifests for downstream)
- Kargo stages align with ArgoCD applications for progressive delivery
- Works with Vagrant (local) or any infrastructure (bare metal, VMs, cloud)
