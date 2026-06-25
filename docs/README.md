## Project is paused to study more instead of doing practical work with the technologies used in the project to strengthen the knowledge I have learned.


# SoC Homelab as code.

A cybersecurity lab built on Hyper-V, designed around DevSecOps and everything-as-code principles. The environment supports a full purple team workflow, infrastructure automation, container orchestration, SIEM, log-based detection, and an isolated attack range  built to the standard of a small security operations team.

---

## Principles

Every component of this environment follows one of these disciplines:

| Discipline | Implementation |
|---|---|
| Infrastructure-as-Code | Packer (golden image), Vagrant (VM provisioning), Terraform (Azure) |
| Configuration-as-Code | Ansible roles and playbooks |
| Detection-as-Code | Sigma rules, converted to LogQL, deployed via CI/CD |
| Observability-as-Code | Loki ruler rules committed to Git |
| Policy-as-Code | Planned — Kyverno on k3s |
| Security-in-the-Pipeline | ansible-lint, kubeconform, Sigma validation on every push |

If something exists only in a UI, it is not done.

---

## Architecture

### Network Zones

    Windows 11 Host (Hyper-V)
    │
    ├── Management Zone (192.168.178.0/24) — External Switch VMs
    │   ├── mgmt01  192.168.178.24   Ansible, monitoring stack, log aggregation
    │   ├── node01  192.168.178.25   k3s control-plane, Wazuh agent, auditd
    │   ├── node02  192.168.178.27   k3s worker, Wazuh agent, auditd
    │   ├── node03  192.168.178.28   Wazuh SIEM (indexer + manager + dashboard)
    │   └── kali01  192.168.178.29   Attacker machine
    │
    └── Attack Zone (10.10.10.0/24) — Lab-Internal switch (isolated, NAT via fw01)
        ├── fw01    192.168.178.33 / 10.10.10.1   Gateway, NAT router, nftables firewall
        └── target01  10.10.10.30                 Vulnerable target (DVWA)

### Services on mgmt01

All services run as Docker Compose on mgmt01.

| Service | Port | Purpose |
|---|---|---|
| Prometheus | 9090 | Metrics collection |
| Grafana | 3000 | Dashboards |
| Loki | 3100 | Log storage and alerting |
| Grafana Alloy | 12345 | Log collection (Docker + systemd journal) |
| cAdvisor | 8080 | Container metrics |
| Node Exporter | 9100 | Host metrics |
| Nginx | 80/443 | Reverse proxy |

### Kubernetes Cluster

k3s on node01 (control-plane) and node02 (worker). Managed from mgmt01 via Tailscale VPN.

    mgmt01 (kubectl) ──► Tailscale VPN ──► node01 (control-plane) ──── node02 (worker)

    Namespaces: monitoring, apps, security

### CI/CD Flow

    Git push to main
         │
         ├── ansible-lint     validates all Ansible roles and playbooks
         ├── kubeconform      validates Kubernetes manifests
         ├── detection        validates Sigma rules, converts to LogQL, deploys to Loki
         └── deploy           kubectl apply to k3s cluster via Tailscale VPN

---

## Stack

| Layer | Technology |
|---|---|
| Hypervisor | Hyper-V on Windows 11 |
| Golden Image | Packer + Ubuntu 24.04 LTS |
| VM Provisioning | Vagrant + PowerShell |
| Operating System | Ubuntu Server 24.04 LTS |
| Configuration Management | Ansible |
| Secret Management | Ansible Vault |
| Containers | Docker Engine + Docker Compose |
| Container Orchestration | Kubernetes (k3s) |
| Package Management | Helm |
| Ingress | nginx ingress controller |
| Metrics | Prometheus + Grafana + cAdvisor + Node Exporter |
| Logs | Loki + Grafana Alloy |
| SIEM | Wazuh 4.x |
| Detection Format | Sigma (converted to Loki LogQL) |
| Firewall | nftables (fw01) |
| VPN | Tailscale |
| Cloud | Microsoft Azure + Terraform |
| CI/CD | GitHub Actions |

---

## Detection-as-Code

Detections live in `detections/` and follow a strict pipeline:

    detections/
    ├── sigma/        Sigma rules — vendor-neutral, source of truth
    ├── loki/         Compiled LogQL output — never edit manually
    └── tests/        Sample log lines for each rule — used in CI

On every push touching `detections/sigma/`, the CI pipeline:

1. Validates syntax of all Sigma rules
2. Converts rules to Loki LogQL
3. Deploys Loki ruler YAML rules to mgmt01 via Tailscale SSH
4. Restarts Loki to apply the new rules

No Wazuh rule exists that is not backed by a Sigma rule in Git.

### Purple Team Playbooks Completed

| Technique | Description | Detection |
|---|---|---|
| T1110.001 | SSH brute force | Wazuh rule 5763 + Loki alert |
| T1548.003 | Sudo escalation failure | Wazuh rule 5404 + Loki alert |
| T1059.004 | Reverse shell via Unix shell | Custom Wazuh rule 100003 + Loki alert |

All playbooks documented in `docs/security/purple-team-playbooks/`.

---

## Repository Structure

    homelab/
    ├── ansible/
    │   ├── ansible.cfg
    │   ├── site.yml                        master playbook
    │   ├── inventories/
    │   │   ├── hosts
    │   │   └── group_vars/all/
    │   │       ├── vars.yml
    │   │       └── vault.yml               encrypted secrets
    │   ├── playbooks/
    │   └── roles/
    │       ├── common/                     base packages, timezone
    │       ├── docker/                     Docker Engine
    │       ├── monitoring/                 Prometheus + Grafana + Loki + cAdvisor
    │       ├── alloy/                      Grafana Alloy log collector
    │       ├── reverse_proxy/              Nginx
    │       ├── node_exporter/              Node Exporter
    │       ├── k3s_server/                 k3s control-plane
    │       ├── k3s_agent/                  k3s worker
    │       ├── gateway/                    nftables NAT + routing for fw01
    │       ├── target/                     vulnerable services for target01
    │       ├── mgmt01_github/              GitHub SSH key from vault
    │       └── mgmt01_hosts/              /etc/hosts management
    │
    ├── detections/
    │   ├── sigma/                          Sigma rules (source of truth)
    │   ├── loki/                           compiled LogQL (CI output)
    │   └── tests/                          sample log fixtures for CI
    │
    ├── monitoring/
    │   └── loki/
    │       └── rules/                      Loki ruler YAML alert rules
    │
    ├── kubernetes/
    │   ├── manifests/
    │   └── helm/
    │
    ├── vagrant/
    │   ├── gateway/                        fw01 Vagrantfile + prep script
    │   └── target01/                       target01 Vagrantfile + prep script
    │
    ├── packer/                             golden image build
    │
    ├── terraform/
    │   └── azure/                          Azure VM + networking
    │
    ├── docs/
    │   ├── architecture.md
    │   ├── build-log.md
    │   ├── add-node.md
    │   ├── mgmt01-disaster-recovery.md
    │   └── security/
    │       └── purple-team-playbooks/
    │
    └── .github/
        └── workflows/
            ├── ansible-lint.yml
            ├── kubernetes-lint.yml
            ├── detection.yml               Sigma validation + Loki deployment
            └── deploy.yml                  kubectl apply via Tailscale

---

## Node Overview

| Host | IP | OS | Role |
|---|---|---|---|
| mgmt01 | 192.168.178.24 | Ubuntu 24.04 | Management, monitoring, Ansible control node |
| node01 | 192.168.178.25 | Ubuntu 24.04 | k3s control-plane, Wazuh agent, auditd |
| node02 | 192.168.178.27 | Ubuntu 24.04 | k3s worker, Wazuh agent, auditd |
| node03 | 192.168.178.28 | Ubuntu 24.04 | Wazuh SIEM (indexer + manager + dashboard) |
| kali01 | 192.168.178.29 | Kali 2026.1 | Attacker machine |
| fw01 | 192.168.178.33 / 10.10.10.1 | Ubuntu 24.04 | Gateway, NAT router, nftables firewall |
| target01 | 10.10.10.30 | Ubuntu 24.04 | Vulnerable target (DVWA, attack zone) |

---

## Key Commands

All Ansible commands run from `~/homelab/ansible`.

    # Connectivity check
    ansible all -m ping

    # Deploy full environment
    ansible-playbook site.yml

    # Deploy monitoring stack only
    ansible-playbook site.yml --limit mgmt01

    # Deploy Wazuh agent on a new node
    ansible-playbook playbooks/wazuh-agent.yml --limit <node>

    # Kubernetes cluster status
    kubectl get nodes
    kubectl get pods -A

    # Validate Sigma rules locally
    sigma check detections/sigma/

    # Convert Sigma rules to LogQL manually
    sigma convert -t loki detections/sigma/<rule>.yml

    # Terraform (from terraform/azure/)
    terraform plan
    terraform apply
    terraform destroy

---

## CI/CD Pipelines

| Workflow | Trigger | What it does |
|---|---|---|
| `ansible-lint.yml` | Push to main | Lints all Ansible roles and playbooks |
| `kubernetes-lint.yml` | Push to main | Validates Kubernetes manifests |
| `detection.yml` | Push to main (detections) | Validates Sigma rules, converts to LogQL, deploys to Loki |
| `deploy.yml` | Push to main (manifests) | Applies manifests to k3s via Tailscale VPN |

---

## Secrets

All secrets stored in Ansible Vault at `ansible/inventories/group_vars/all/vault.yml`. The vault password lives at `~/.vault_pass` on mgmt01 and is never committed.

GitHub Actions secrets required:

| Secret | Purpose |
|---|---|
| `KUBECONFIG` | Base64-encoded kubeconfig for k3s cluster |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client ID for CI runners |
| `TS_OAUTH_SECRET` | Tailscale OAuth secret for CI runners |
| `MGMT01_SSH_KEY` | Private key for ansible user on mgmt01 (CI deployment) |

---

## Roadmap

### In Progress
- Phase 3 — Observability-as-Code (Grafana dashboards and Loki rules in Git)
- Phase 4 — Policy-as-Code (Kyverno admission policies on k3s)

### Planned
- Phase 5 — Centralized auth (Authentik) + internal CA (Step CA)
- Phase 6 — Security-in-the-pipeline (Trivy, image pinning, CIS hardening role)
- Phase 7 — Case management (TheHive) + network detection (Suricata on fw01)
- Phase 8 — 1-click install (PowerShell bootstrap + master Ansible playbook)
