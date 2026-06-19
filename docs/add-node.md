i# Adding a New Node to the SOC Lab

## Purpose

This document describes the standard process for adding a new Ubuntu node to the SOC homelab environment.

It ensures that all nodes are deployed in a consistent, repeatable way using Ansible and integrated automatically into monitoring.

---

## Naming and IP Convention

Each node follows this format:

* Hostname: `nodeXX` (e.g. `node01`, `node02`)
* IP address: assigned statically in the home network (example: `192.168.178.XX`)

> Example:
>
> * `node01` → `192.168.178.25`
> * `node02` → `192.168.178.27`

When following this guide, replace:

* `nodeXX` with the actual node name
* `<NODE_IP>` with the assigned IP address

---

# Step 1 — Create the Virtual Machine (Hyper-V)

Create a new VM using Ubuntu Server 24.04 LTS.

Recommended configuration:

| Setting | Value                   |
| ------- | ----------------------- |
| CPU     | 2 vCPU                  |
| Memory  | 4 GB                    |
| Disk    | 40+ GB                  |
| Network | External Virtual Switch |

Set:

* Hostname: `nodeXX`
* IP: `<NODE_IP>`

---

# Step 2 — Install Ubuntu

Install Ubuntu Server 24.04 LTS.

During setup:

* Create a temporary admin user (e.g. `k0r4y`)
* Enable OpenSSH Server

---

# Step 3 — Verify Basic Network Setup

On the new VM:

```bash
hostname
ip addr
```

Expected:

* Hostname matches `nodeXX`
* IP matches `<NODE_IP>`

---

# Step 4 — Update System

```bash
sudo apt update
sudo apt upgrade -y
```

---

# Step 5 — Remove Old SSH Key (on mgmt01)

If the node previously existed at the same IP:

```bash
ssh-keygen -R <NODE_IP>
```

This avoids SSH host key conflicts.

---

# Step 6 — Temporary Inventory Setup

Edit:

```
ansible/inventories/hosts
```

Add or update:

```ini
nodeXX ansible_host=<NODE_IP> ansible_user=<TEMP_USER>
```

Example:

```ini
node02 ansible_host=192.168.178.27 ansible_user=k0r4y
```

---

# Step 7 — Bootstrap Ansible User

Run from `mgmt01`:

```bash
ansible-playbook \
  -i ansible/inventories/hosts \
  ansible/playbooks/bootstrap-ansible-user.yml \
  --limit nodeXX \
  --ask-become-pass
```

This will:

* Create the `ansible` user
* Install SSH key access
* Enable passwordless sudo

---

# Step 8 — Switch to Ansible User

Remove the temporary user override:

```ini
ansible_user=<TEMP_USER>
```

Ensure the inventory uses:

```ini
ansible_user=ansible
```

---

# Step 9 — Verify Ansible Connectivity

```bash
ansible nodeXX -m ping
```

Expected result:

```text
pong
```

---

# Step 10 — Install Docker

```bash
ansible-playbook \
  -i ansible/inventories/hosts \
  ansible/docker.yml \
  --limit nodeXX
```

Verify:

```bash
ansible nodeXX -m shell -a "docker --version"
```

---

# Step 11 — Deploy Node Exporter

```bash
ansible-playbook \
  -i ansible/inventories/hosts \
  ansible/playbooks/node-exporter.yml \
  --limit nodeXX
```

Verify:

```bash
ansible nodeXX -m shell -a "docker ps"
```

Expected:

* `node-exporter` container running

---

# Step 12 — Verify Metrics Endpoint

From `mgmt01`:

```bash
curl http://<NODE_IP>:9100/metrics | head
```

Expected:

* Prometheus metrics output is returned

---

# Step 13 — Verify Monitoring

### Prometheus

Check targets:

```
http://<MGMT01_IP>:9090/targets
```

Expected:

* `nodeXX:9100` is **UP**

### Grafana

Verify dashboards:

* CPU metrics visible
* Memory metrics visible
* Node appears in dashboards

---

# Final State

A successful deployment results in:

```
nodeXX
├── Ubuntu Server 24.04 LTS
├── ansible user
├── Docker Engine
└── node-exporter (container)
```

The node is now:

* Managed via Ansible
* Monitored via Prometheus
* Visualized in Grafana
* Rebuildable from scratch

```
```

