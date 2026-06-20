# mgmt01 Disaster Recovery Guide

## Overview

Full procedure to rebuild mgmt01 from scratch after VM loss or corruption.

## Prerequisites

- Ubuntu Server 24.04 LTS ISO
- Access to Hyper-V Manager on Windows host
- Vault password (stored securely offline)
- GitHub account access

---

## Step 1 — Create new VM in Hyper-V

- Generation: 2
- Memory: 4096 MB
- Disk: 20 GB minimum
- Network: external virtual switch
- Hostname: mgmt01
- User: k0r4y
- Enable OpenSSH during install

---

## Step 2 — Bootstrap

SSH in from Windows terminal, then run:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/k0r4y/homelab.git
cd homelab
./bootstrap-mgmt01.sh
```

This installs dependencies and configures passwordless sudo. Requires sudo password once.

---

## Step 3 — Create vault password file

```bash
echo "your-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

---

## Step 4 — Install Ansible collections

```bash
cd ~/homelab/ansible
ansible-galaxy collection install -r requirements.yml
```

---

## Step 5 — Run rebuild playbook

```bash
ansible-playbook playbooks/rebuild-mgmt01.yml
```

This deploys:
- Common packages
- Docker Engine
- GitHub SSH key and git configuration
- Monitoring stack (Prometheus, Grafana, cAdvisor)
- Nginx reverse proxy
- Node Exporter

---

## Step 6 — Verify

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
systemctl status nginx --no-pager | head -5
ssh -T git@github.com
```

---

## Step 7 — Restore Grafana dashboards

Re-import dashboards manually:
- Connections → Data sources → Add Prometheus → URL: `http://prometheus:9090`
- Dashboards → Import → ID `1860` (Node Exporter)
- Dashboards → Import → ID `14282` (cAdvisor)

---

## Optional: Full wipe and rebuild

```bash
ansible-playbook playbooks/rebuild-mgmt01.yml -e wipe_data=true
```

WARNING: permanently deletes `/opt/monitoring` and `/opt/reverse_proxy`.
