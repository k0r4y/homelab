# Adding a New Node to the SOC Lab

## Purpose

This document describes the standard process for adding a new Ubuntu node to the SOC homelab environment.

It ensures that all nodes are deployed in a consistent, repeatable way using Ansible and integrated automatically into monitoring, security, and Kubernetes (when applicable).

---

## Naming and IP Convention

Each node follows this format:

- Hostname: `nodeXX` (e.g. `node01`, `node02`, `node03`)
- IP address: assigned statically in the home network (example: `192.168.178.XX`)

---

## Step 1 — Create the Virtual Machine (Hyper-V)

Create a new VM using Ubuntu Server 24.04 LTS.

**Recommended configuration:**

| Setting | Value                   |
|---------|-------------------------|
| CPU     | 2 vCPU                  |
| Memory  | 4 GB                    |
| Disk    | 40+ GB                  |
| Network | External Virtual Switch |

Set:
- Hostname: `nodeXX`
- IP: `<NODE_IP>`

---

## Step 2 — Install Ubuntu

Install Ubuntu Server 24.04 LTS.

During setup:
- Create a temporary admin user (e.g. `k0r4y`)
- Enable OpenSSH Server

---

## Step 3 — Bootstrap the Node

On the new VM, run basic updates:

    sudo apt update && sudo apt upgrade -y

---

## Step 4 — Temporary Inventory Entry (on mgmt01)

Edit `ansible/inventories/hosts` and add:

    nodeXX ansible_host=<NODE_IP> ansible_user=k0r4y

---

## Step 5 — Bootstrap Ansible User

Run from `mgmt01`:

    ansible-playbook \
      -i ansible/inventories/hosts \
      ansible/playbooks/bootstrap-ansible-user.yml \
      --limit nodeXX \
      --ask-become-pass \
      --ask-pass

---

## Step 6 — Finalize Inventory

Remove the temporary `ansible_user=k0r4y` line so it uses the standard `ansible` user.

---

## Step 7 — Verify Connectivity

    ansible nodeXX -m ping

---

## Step 8 — Deploy Docker

    ansible-playbook \
      -i ansible/inventories/hosts \
      ansible/docker.yml \
      --limit nodeXX

---

## Step 9 — Deploy Node Exporter

    ansible-playbook \
      -i ansible/inventories/hosts \
      ansible/playbooks/node-exporter.yml \
      --limit nodeXX

---

## Step 10 — Additional Roles (as needed)

- For k3s agent: `ansible-playbook playbooks/k3s-agent.yml --limit nodeXX`
- For Wazuh agent: `ansible-playbook playbooks/wazuh-agent.yml --limit nodeXX`

---

## Final Verification

- `ansible nodeXX -m shell -a "docker ps"`
- Check Prometheus targets at `http://mgmt01:9090/targets`
- Verify node appears in Grafana

---

**Result**: The new node is fully managed by Ansible, monitored, and secured.
