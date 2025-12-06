# Rancher and RKE2 Patching

Simple playbooks for upgrading Rancher and RKE2.

## Quick Start

```bash
# 1. Edit versions
vim patch-versions.yml

# 2. Run upgrade
./patch.sh
```

## Configuration

Edit `patch-versions.yml`:

```yaml
rke2_version: "v1.31.4+rke2r1"
rancher_version: "2.9.3"
cert_manager_version: "v1.16.2"
```

## Manual Steps

```bash
# Backup
ansible-playbook -i ../inventory/hosts.yml backup.yml

# Upgrade RKE2
ansible-playbook -i ../inventory/hosts.yml upgrade-rke2.yml

# Upgrade Rancher
ansible-playbook -i ../inventory/hosts.yml upgrade-rancher.yml
```

## Rollback

```bash
ansible-playbook -i ../inventory/hosts.yml rollback.yml
```

## Notes

- Backups are created automatically in `/var/backups/rancher/`
- Upgrades happen one node at a time (rolling)
- Test in dev/staging first
