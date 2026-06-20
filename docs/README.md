# Homelab Infrastructure

A personal DevOps and Security Operations lab built on Hyper-V, designed to demonstrate production-grade infrastructure automation, container orchestration, monitoring, security operations, and cloud integration.

---

## Stack

| Layer | Technology |
|---|---|
| Virtualisation | Hyper-V on Windows 11 |
| Operating System | Ubuntu Server 24.04 LTS |
| Configuration Management | Ansible |
| Secret Management | Ansible Vault |
| Containers | Docker Engine + Docker Compose |
| Container Orchestration | Kubernetes (k3s) |
| Package Management | Helm |
| Ingress | nginx ingress controller |
| Monitoring | Prometheus, Grafana, cAdvisor, Node Exporter |
| Security | Wazuh SIEM |
| VPN | Tailscale |
| Cloud | Microsoft Azure |
| Infrastructure as Code | Terraform (azurerm provider) |
| CI/CD | GitHub Actions |
| Version Control | Git + GitHub |

---

## Architecture

    Windows 11 Host (Hyper-V)
    │
    ├── mgmt01 (192.168.178.24)
    │   ├── Ansible control node
    │   ├── Nginx reverse proxy
    │   ├── Prometheus
    │   ├── Grafana
    │   ├── cAdvisor
    │   ├── Node Exporter
    │   └── Wazuh Agent
    │
    ├── node01 (192.168.178.25)
    │   ├── k3s control-plane
    │   ├── Docker Engine
    │   ├── Wazuh Agent
    │   └── Tailscale (100.99.132.22)
    │
    ├── node02 (192.168.178.27)
    │   ├── k3s worker
    │   ├── Docker Engine
    │   └── Wazuh Agent
    │
    └── node03 (192.168.178.28)
        ├── Wazuh Indexer
        ├── Wazuh Manager
        ├── Wazuh Dashboard
        └── Node Exporter

### Kubernetes Cluster

    mgmt01 (kubectl)
         │
         │ Tailscale VPN
         │
    node01 (control-plane) ──── node02 (worker)
         │
         ├── Namespace: monitoring
         │   └── Node Exporter DaemonSet
         │
         ├── Namespace: apps
         │   ├── hello-world Deployment (2 replicas)
         │   └── nginx ingress controller (Helm)
         │
         └── Namespace: security

### Monitoring Flow

    node01 Node Exporter (:9100) ──┐
    node02 Node Exporter (:9100) ──┤
    node03 Node Exporter (:9100) ──┼──► Prometheus ──► Grafana
    mgmt01 Node Exporter (:9100) ──┤
    cAdvisor (:8080) ──────────────┘

### CI/CD Flow

    Git push to main
         │
         ├── ansible-lint ──► validates all playbooks and roles
         ├── kubeconform  ──► validates Kubernetes manifests
         └── kubectl apply ──► deploys manifests to k3s via Tailscale VPN

---

## Repository Structure

    homelab/
    ├── bootstrap-mgmt01.sh
    │
    ├── ansible/
    │   ├── ansible.cfg
    │   ├── requirements.yml
    │   ├── inventories/
    │   │   ├── hosts
    │   │   └── group_vars/
    │   │       └── all/
    │   │           ├── vars.yml
    │   │           └── vault.yml          ← encrypted secrets
    │   │
    │   ├── playbooks/
    │   │   ├── bootstrap-ansible-user.yml
    │   │   ├── k3s.yml
    │   │   ├── k3s-agent.yml
    │   │   ├── mgmt01.yml
    │   │   ├── monitoring.yml
    │   │   ├── node-exporter.yml
    │   │   ├── rebuild-mgmt01.yml
    │   │   ├── wazuh.yml
    │   │   └── wazuh-agent.yml
    │   │
    │   └── roles/
    │       ├── common/
    │       ├── docker/
    │       ├── k3s_agent/
    │       ├── k3s_server/
    │       ├── mgmt01_github/
    │       ├── mgmt01_hosts/
    │       ├── monitoring/
    │       ├── node_exporter/
    │       └── reverse_proxy/
    │
    ├── kubernetes/
    │   ├── manifests/
    │   │   ├── namespaces.yaml
    │   │   ├── apps/
    │   │   │   └── hello-world.yaml
    │   │   └── monitoring/
    │   │       └── node-exporter.yaml
    │   └── helm/
    │       └── kube-prometheus-stack-values.yaml
    │
    ├── terraform/
    │   └── azure/
    │       ├── providers.tf
    │       ├── variables.tf
    │       ├── main.tf
    │       └── outputs.tf
    │
    ├── docs/
    │   ├── architecture.md
    │   ├── build-log.md
    │   ├── add-node.md
    │   ├── mgmt01-disaster-recovery.md
    │   └── ssh-agent-setup.md
    │
    └── .github/
        └── workflows/
            ├── ansible-lint.yml
            ├── kubernetes-lint.yml
            └── deploy.yml

---

## Node Overview

| Host | IP | Role | Key Services |
|---|---|---|---|
| mgmt01 | 192.168.178.24 | Management | Ansible, Nginx, Prometheus, Grafana, cAdvisor |
| node01 | 192.168.178.25 | k3s control-plane | Docker, k3s, Wazuh Agent, Tailscale |
| node02 | 192.168.178.27 | k3s worker | Docker, k3s agent, Wazuh Agent |
| node03 | 192.168.178.28 | Security | Wazuh Indexer, Manager, Dashboard |

---

## Automation

### Rebuild mgmt01 from scratch

All state is in Git and Ansible Vault. To fully rebuild mgmt01 after a failure:

    # 1. Clone the repo on a fresh Ubuntu 24.04 VM
    git clone https://github.com/k0r4y/homelab.git
    cd homelab

    # 2. Bootstrap dependencies and sudo access
    ./bootstrap-mgmt01.sh

    # 3. Create the vault password file
    echo "your-vault-password" > ~/.vault_pass
    chmod 600 ~/.vault_pass

    # 4. Install Ansible collections
    cd ansible
    ansible-galaxy collection install -r requirements.yml

    # 5. Run the rebuild playbook
    ansible-playbook playbooks/rebuild-mgmt01.yml

This deploys: Docker, monitoring stack, nginx reverse proxy, GitHub SSH key, workstation SSH key, node exporter, and git configuration — fully unattended.

See [docs/mgmt01-disaster-recovery.md](docs/mgmt01-disaster-recovery.md) for the full runbook.

### Add a new node

See [docs/add-node.md](docs/add-node.md) for the step-by-step runbook.

---

## Cloud Infrastructure (Azure + Terraform)

Azure infrastructure is defined as code using Terraform with the `azurerm` provider. Terraform state is stored remotely in Azure Blob Storage.

Resources defined:

- Resource group
- Virtual network and subnet
- Network security group (SSH ingress)
- Public IP (static)
- Network interface
- Ubuntu 24.04 LTS VM (`Standard_D2s_v6`, West Europe)

Deploy and destroy on demand:

    cd terraform/azure
    terraform init
    terraform plan
    terraform apply
    terraform destroy

---

## CI/CD Pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `ansible-lint.yml` | Push to main | Lints all Ansible playbooks and roles |
| `kubernetes-lint.yml` | Push to main | Validates Kubernetes manifests with kubeconform |
| `deploy.yml` | Push to main (manifests only) | Applies manifests to k3s cluster via Tailscale VPN |

---

## Key Commands

All Ansible commands run from `~/homelab/ansible`.

    # Connectivity check
    ansible all -m ping

    # Full mgmt01 rebuild
    ansible-playbook playbooks/rebuild-mgmt01.yml

    # Deploy monitoring stack
    ansible-playbook playbooks/monitoring.yml

    # Install Wazuh agent on a new node
    ansible-playbook playbooks/wazuh-agent.yml --limit <node>

    # Kubernetes cluster status
    kubectl get nodes
    kubectl get pods -A
    kubectl get ingress -A

    # Helm releases
    helm list -A

    # Test ingress routing
    curl -H "Host: hello.homelab" http://192.168.178.25

    # Terraform (from terraform/azure/)
    terraform plan
    terraform apply
    terraform destroy

---

## Documentation

| Document | Description |
|---|---|
| [architecture.md](docs/architecture.md) | Infrastructure architecture and design |
| [build-log.md](docs/build-log.md) | Chronological build log |
| [add-node.md](docs/add-node.md) | Runbook for adding a new node |
| [mgmt01-disaster-recovery.md](docs/mgmt01-disaster-recovery.md) | Full disaster recovery procedure |
| [ssh-agent-setup.md](docs/ssh-agent-setup.md) | SSH key and agent configuration |

---

## Roadmap

- [ ] Loki for centralised log aggregation
- [ ] AKS — managed Kubernetes in Azure
- [ ] Terraform provisioning of Azure VM with Ansible configuration
- [ ] Wazuh alert rules and detection engineering
- [ ] Certificate management with cert-manager
