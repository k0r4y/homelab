# Architecture

## Infrastructure Layout

Windows Gaming PC
│
└── Hyper-V
    │
    ├── mgmt01 (192.168.178.24)
    │   │
    │   ├── SSH Management
    │   ├── Ansible Control Node
    │   ├── Git Repository
    │   ├── Nginx Reverse Proxy
    │   ├── Prometheus
    │   ├── Grafana
    │   └── cAdvisor
    │
    ├── node01 (192.168.178.25)
    │   │
    │   ├── Docker Engine
    │   ├── k3s Server (control-plane)
    │   └── Node Exporter (Kubernetes DaemonSet)
    │
    └── node02 (192.168.178.27)
        │
        ├── Docker Engine
        ├── k3s Agent (worker)
        └── Node Exporter (Kubernetes DaemonSet)


## Kubernetes Architecture

┌─────────────────────────────────────┐
│         k3s Cluster                  │
│                                       │
│  ┌─────────────────────────────┐    │
│  │   node01 (control-plane)    │    │
│  │  ┌──────────────────────┐  │    │
│  │  │  Node Exporter       │  │    │
│  │  │  (DaemonSet)         │  │    │
│  │  └──────────────────────┘  │    │
│  └─────────────────────────────┘    │
│                                       │
│  ┌─────────────────────────────┐    │
│  │   node02 (worker)           │    │
│  │  ┌──────────────────────┐  │    │
│  │  │  Node Exporter       │  │    │
│  │  │  (DaemonSet)         │  │    │
│  │  └──────────────────────┘  │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘


## Management Flow

Administrator
      │
      ▼
   mgmt01
      │
      ├── SSH ─────► node01
      │
      └── SSH ─────► node02


## Ansible Automation Flow

Ansible Playbooks
        │
        ▼
      mgmt01
        │
        ├── Deploy Docker
        ├── Manage Configuration
        ├── Execute Commands
        │
        ├──► node01
        │
        └──► node02


## Reverse Proxy Flow

Browser
   │
   ▼
192.168.178.24
   │
   ▼
Nginx Reverse Proxy (mgmt01)
   │
   ├── /grafana/ ───► localhost:3000
   │
   └── /prometheus/ ───► localhost:9090


## Monitoring Flow

node01 (Node Exporter)
          │
          │
          ▼
      Prometheus
          ▲
          │
          │
node02 (Node Exporter)

cAdvisor (container metrics)
    │
    ▼
Prometheus
    │
    ▼
Grafana


## Current Services

| Host | Purpose | Services |
|------|---------|----------|
| mgmt01 | Management Node | SSH, Ansible, Git, Nginx, Prometheus, Grafana, cAdvisor |
| node01 | Control Plane | Docker, k3s Server, Node Exporter (K8s) |
| node02 | Worker Node | Docker, k3s Agent, Node Exporter (K8s) |


## Kubernetes Namespaces

| Namespace | Purpose |
|-----------|---------|
| monitoring | Observability tools (Node Exporter, future: Prometheus, Grafana) |
| apps | Application workloads |
| security | Security tooling (future: Wazuh) |


## Future Expansion

Planned additions:

- Wazuh security monitoring
- Prometheus/Grafana migration to Kubernetes
- Centralized logging
- Azure integration
- CI/CD pipelines improvements
- Container orchestration and scaling
