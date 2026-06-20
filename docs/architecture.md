# Architecture

## Overview

This SOC homelab is a production-pattern infrastructure environment built on Hyper-V. It demonstrates full-stack automation with Ansible, container orchestration with k3s, centralized monitoring, security operations with Wazuh, and hybrid cloud extension via Terraform.

The design prioritizes:
- Rebuildability — mgmt01 can be fully recreated from Git + Vault
- Automation — Everything is Ansible-driven where possible
- Observability — Comprehensive metrics from all nodes
- Security — Dedicated automation user, key-based SSH, Wazuh SIEM
- Scalability — Easy node addition and Kubernetes workloads

---

## Physical Infrastructure

**Hypervisor**: Windows 11 + Hyper-V (External Virtual Switch)

**Nodes**:

| Host      | IP Address       | Role                              | Key Services |
|-----------|------------------|-----------------------------------|--------------|
| **mgmt01** | 192.168.178.24  | Management & Observability        | Ansible, Docker, Nginx Reverse Proxy, Prometheus, Grafana, cAdvisor, Wazuh Agent |
| **node01** | 192.168.178.25  | k3s Control Plane                 | k3s Server, Docker, Wazuh Agent, Tailscale (100.99.132.22) |
| **node02** | 192.168.178.27  | k3s Worker                        | k3s Agent, Docker, Wazuh Agent |
| **node03** | 192.168.178.28  | Security Operations               | Wazuh All-in-One (Indexer + Manager + Dashboard), Node Exporter |

---

## Logical Architecture

### Management Layer (mgmt01)
- Central Ansible control node
- GitHub SSH key + git configuration
- Nginx reverse proxy (single entry point)
- Monitoring stack (Prometheus + Grafana + cAdvisor)
- Wazuh agent reporting to node03

### Compute / Orchestration Layer
- **k3s Kubernetes Cluster** (node01 + node02)
  - Namespaces: `monitoring`, `apps`, `security`
  - nginx-ingress controller (Helm)
  - Node Exporter DaemonSet
  - Sample workload: `hello-world` Deployment + Ingress (`hello.homelab`)

### Security Layer
- **Wazuh SIEM** on node03 with agents on all nodes
- Key-based SSH authentication only
- Passwordless sudo for `ansible` user
- Secrets managed via Ansible Vault

### Monitoring & Observability
- **Prometheus** scrapes:
  - Node Exporter (all 4 nodes)
  - cAdvisor (containers on mgmt01)
  - Kubernetes components (via future service discovery)
- **Grafana** for visualization
- **cAdvisor** for container metrics

---

## Network Architecture

    Windows Workstation (Hyper-V Host)
            │
            ▼
    External Virtual Switch (192.168.178.0/24)
            │
       ┌────┼────┐
       │         │
    mgmt01    node01 ── Tailscale VPN ── node01 (external access)
       │         │
       │       node02
       │
    node03 (Wazuh)

    Nginx Reverse Proxy (mgmt01:80)
       ├── /grafana/    → localhost:3000
       ├── /prometheus/ → localhost:9090
       └── (Future) /wazuh/ → node03

---

## Data Flow

### Monitoring Flow

    Node Exporters (all nodes) ──┐
    cAdvisor (mgmt01)            │
    k3s metrics                  ├─► Prometheus (:9090) ──► Grafana (:3000)
                                 │
    Wazuh Agents (all nodes) ───► Wazuh Manager (node03)

### Automation Flow

    GitHub Repo
        │
        ▼
    mgmt01 (Ansible)
        ├── bootstrap-ansible-user.yml
        ├── rebuild-mgmt01.yml
        ├── docker.yml
        ├── k3s.yml + k3s-agent.yml
        └── playbooks for monitoring, Wazuh, etc.

### CI/CD Flow

    Git Push → GitHub Actions
        ├── ansible-lint
        ├── kubeconform (Kubernetes manifests)
        └── kubectl apply (via Tailscale) → k3s cluster

---

## Technology Stack Summary

| Category               | Tools |
|------------------------|-------|
| Infrastructure as Code | Ansible, Terraform (Azure) |
| Orchestration          | k3s, Docker, Helm |
| Monitoring             | Prometheus, Grafana, cAdvisor, Node Exporter |
| Security               | Wazuh, SSH keys, Vault |
| Networking             | Nginx, Tailscale |
| CI/CD                  | GitHub Actions |
| Cloud                  | Azure (Terraform) |

---

## Design Principles

1. Idempotency & Rebuildability — All roles are designed to be safe to re-run
2. Separation of Concerns — Management, compute, and security layers are distinct
3. Single Source of Truth — Git + Ansible Vault
4. Observability First — Every new component gets monitoring
5. Security by Default — No passwords in transit, dedicated automation user

---

## Future Extensions

- Loki + Promtail for centralized logging
- Hybrid cloud: Terraform-provisioned Azure VM auto-configured by Ansible
- AKS (Azure Kubernetes Service)
- cert-manager for TLS
- Advanced Wazuh detection rules
- GitOps with ArgoCD or Flux

---

**Repository**: https://github.com/k0r4y/homelab

Last updated: June 2026
