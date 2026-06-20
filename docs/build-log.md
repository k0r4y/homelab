# Build Log

#### 2026-06-19

### Infrastructure Automation
- Created Ansible inventory for homelab nodes
- Configured SSH key-based authentication
- Automated Docker installation using Ansible
- Added Docker group membership for ansible user
- Verified Docker deployment across node01 and node02

### Reverse Proxy
- Installed Nginx on mgmt01
- Configured reverse proxy routing
- Added access paths:
  - /grafana/
  - /prometheus/
- Opened TCP port 80 in UFW
- Verified access from Windows host

### Monitoring
- Installed Node Exporter on node01
- Installed Node Exporter on node02
- Deployed Prometheus on mgmt01
- Deployed Grafana on mgmt01
- Deployed cAdvisor on mgmt01
- Configured Prometheus scrape targets
- Verified target health status
- Imported Grafana dashboards
- Verified host and container metrics collection

### Current Status
- 3-node Ubuntu environment operational
- Centralized management through Ansible
- Docker running on node01 and node02
- Reverse proxy operational
- Infrastructure monitoring operational
- Container monitoring operational

---

#### 2026-06-20

### Architecture & Documentation Updates
- Regenerated and modernized `docs/architecture.md` with current node overview, logical layers, network diagrams, and data flows
- Aligned documentation with live state: k3s cluster, Wazuh, Tailscale, and CI/CD pipelines
- Updated node table and future extensions section

### Infrastructure Status (as of checkpoint)
- Full Ansible-managed 4-node environment (mgmt01 + node01/02/03)
- mgmt01 fully rebuildable from scratch via `rebuild-mgmt01.yml`
- Two-node k3s Kubernetes cluster with namespaces (`monitoring`, `apps`, `security`)
- nginx-ingress controller + `hello-world` demo app with hostname-based routing
- Wazuh SIEM (all-in-one on node03 + agents on all nodes)
- Prometheus + Grafana + cAdvisor + Node Exporter (host + DaemonSet)
- Tailscale VPN between mgmt01 and node01
- Terraform Azure deployment validated (8 resources, remote state)
- GitHub Actions: ansible-lint, kubeconform, and automated kubectl deploy all passing

### Monitoring & Observability
- Prometheus scraping all 4 nodes + cAdvisor
- Grafana dashboards for infrastructure and container metrics
- Node Exporter running on every host and as DaemonSet in k8s

### Security & Access
- Dedicated `ansible` user with passwordless sudo across nodes
- SSH key authentication only (GitHub key + workstation key)
- Wazuh agents reporting to central manager on node03

### Current Status
- Fully automated, rebuildable homelab infrastructure
- Centralized management via mgmt01
- Production-grade patterns for monitoring, orchestration, and security
- CI/CD pipeline operational
- Ready for next phase: centralized logging (Loki) and hybrid cloud
