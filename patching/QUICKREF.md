# Quick Reference

## Run Upgrade

```bash
./patch.sh
```

## Set Versions

```bash
vim patch-versions.yml
```

```yaml
rke2_version: "v1.31.4+rke2r1"
rancher_version: "2.9.3"
cert_manager_version: "v1.16.2"
```

## Manual Steps

```bash
ansible-playbook -i ../inventory/hosts.yml backup.yml
ansible-playbook -i ../inventory/hosts.yml upgrade-rke2.yml
ansible-playbook -i ../inventory/hosts.yml upgrade-rancher.yml
```

## Rollback

```bash
ansible-playbook -i ../inventory/hosts.yml rollback.yml
```
