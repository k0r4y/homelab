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
  - /node01/
  - /node02/
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
