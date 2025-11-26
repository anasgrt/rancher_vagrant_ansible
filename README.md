# Ansible Deployment for Rancher + RKE2

Deploys the same Rancher multi-cluster environment as the Vagrant setup, but works with any SSH-accessible hosts.

## Quick Start

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

- **Management Cluster** (local-ctrl): RKE2 + Rancher + cert-manager + ArgoCD + Fleet
- **Downstream Cluster** (key): RKE2 control plane + worker + Rancher agents

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
- `argocd_enabled`: Enable ArgoCD
- `fleet_enabled`: Enable Fleet GitOps

## Access

After deployment:

**Rancher UI:**
- URL: `https://rancher.local.test` (or your configured hostname)
- Username: `admin`
- Password: `SuperAdmin123!` (or configured)
- **Important**: Import CA cert from `/tmp/rancher_shared/rancher-ca.crt`

**ArgoCD** (if enabled):
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
# URL: https://localhost:8080
# Password: cat /tmp/rancher_shared/argocd_password
```

## Shared Files

Files are shared via `/tmp/rancher_shared/`:
- `rancher-ca.crt` - CA certificate
- `rancher_token` - API token
- `kubeconfig-*` - Cluster configs
- `node-token*` - Join tokens

## Troubleshooting

```bash
# Check connectivity
ansible -i inventory/hosts.yml all -m ping

# Verbose output
ansible-playbook -i inventory/hosts.yml site.yml -vv

# Check shared files
ls -la /tmp/rancher_shared/

# SSH to hosts
ssh ubuntu@192.168.56.10
```

## Structure

```
ansible/
├── site.yml                 # Main playbook
├── inventory/hosts.yml      # Host definitions
├── group_vars/all.yml       # Configuration
└── roles/                   # 9 deployment roles
    ├── system_setup         # DNS, packages, hostname
    ├── rke2_server          # RKE2 management
    ├── rancher_server       # Rancher + cert-manager
    ├── rke2_downstream_control
    ├── rancher_agent_control
    ├── rke2_downstream_worker
    ├── rancher_agent_worker
    ├── argocd
    └── fleet_setup
```

## Notes

- Playbooks are idempotent (safe to re-run)
- Same configuration as Vagrant (`vagrant-config.yml` → `group_vars/all.yml`)
- Works with any infrastructure (bare metal, VMs, cloud)
