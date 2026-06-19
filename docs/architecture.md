# Architecture

## Infrastructure Layout

```text
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
    │   └── Node Exporter
    │
    └── node02 (192.168.178.27)
        │
        ├── Docker Engine
        └── Node Exporter
```

---

## Management Flow

```text
Administrator
      │
      ▼
   mgmt01
      │
      ├── SSH ─────► node01
      │
      └── SSH ─────► node02
```

---

## Ansible Automation Flow

```text
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
```

---

## Reverse Proxy Flow

```text
Browser
   │
   ▼
192.168.178.24
   │
   ▼
Nginx Reverse Proxy (mgmt01)
   │
   ├── /node01/ ───► 192.168.178.25:8081
   │
   └── /node02/ ───► 192.168.178.27:8082
```

---

## Monitoring Flow

```text
node01 (Node Exporter)
          │
          │
          ▼
      Prometheus
          ▲
          │
          │
node02 (Node Exporter)

cAdvisor
    │
    ▼
Prometheus
    │
    ▼
Grafana
```

---

## Current Services

| Host | Purpose |
|--------|----------|
| mgmt01 | SSH, Ansible, Git, Nginx, Prometheus, Grafana, cAdvisor |
| node01 | Docker Engine, Node Exporter |
| node02 | Docker Engine, Node Exporter |

---

## Future Expansion

Planned additions:

- Docker Compose deployments
- Wazuh security monitoring
- Centralized logging
- Kubernetes cluster
- Azure integration
- CI/CD pipelines
- Infrastructure as Code improvements
- Container orchestration and scaling
