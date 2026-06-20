# mgmt01 Disaster Recovery Guide (Hyper-V + Ansible Homelab)

This document describes the complete procedure to rebuild the `mgmt01` management node from scratch in the event of system failure, corruption, or full VM loss.

It assumes:
- Ubuntu Server running as a Hyper-V virtual machine
- Infrastructure managed using Ansible
- Configuration stored in a GitHub repository
- mgmt01 acts as the central management and monitoring node

# 1. Recovery Overview

If `mgmt01` is lost, the recovery process follows these steps:

1. Recreate the Ubuntu VM in Hyper-V
2. Install minimal system dependencies (git, python3, ansible)
3. Clone the homelab repository from GitHub
4. Validate Ansible inventory configuration
5. Execute the rebuild playbook
6. Verify service health (Grafana, nginx, monitoring stack)

# 2. Recreate the Virtual Machine (Hyper-V)

## 2.1 Create a new VM

- Open Hyper-V Manager
- Select “New Virtual Machine”
- Name: mgmt01
- Generation: Generation 2
- Memory: 2–4 GB recommended
- Network: Attach to existing virtual switch
- Disk: Minimum 20 GB recommended

## 2.2 Install Ubuntu Server

Attach the Ubuntu Server ISO and complete installation.

Recommended installation options:
- OpenSSH Server enabled during installation
- Administrative user created during setup
- Hostname set to: mgmt01

After installation, confirm SSH access:

ssh <user>@<mgmt01-ip>

# 3. Install Required Base Tools

sudo apt update
sudo apt install -y git python3 python3-pip ansible

Purpose:
- git: retrieve infrastructure repository
- python3: required runtime for Ansible
- ansible: configuration management engine

# 4. Clone Infrastructure Repository

git clone https://github.com/<your-user>/homelab.git
cd homelab

# 5. Verify Ansible Inventory

Ensure mgmt01 exists:

[mgmt01]
mgmt01 ansible_host=<ip-address> ansible_user=<ssh-user>

Verify:

cat ansible/inventories/hosts

# 6. Run the Rebuild Process

## Dry run

ansible-playbook -i ansible/inventories/hosts ansible/playbooks/rebuild-mgmt01.yml --check

## Full rebuild

ansible-playbook -i ansible/inventories/hosts ansible/playbooks/rebuild-mgmt01.yml

## Optional wipe mode

wipe_data: true

This will:
- Stop containers
- Remove containers
- Delete /opt/monitoring
- Delete /opt/reverse_proxy

# 7. Services Deployed

- Prometheus + Grafana
- Nginx reverse proxy
- Node exporter

# 8. Verification

curl http://localhost:3000
curl http://localhost

# 9. Troubleshooting

docker ps -a
systemctl status docker
systemctl status nginx

# End of Document

