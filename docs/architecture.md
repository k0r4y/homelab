# Architecture

## Overview

This homelab is built on a Windows Hyper-V host and consists of a management node and two managed container hosts.

The management node provides:

- SSH administration
- Ansible automation
- Git repository management
- Nginx reverse proxy services

The managed nodes provide:

- Docker container runtime
- Application hosting
- Ansible-managed configuration

---

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
    │   └── Nginx Reverse Proxy
    │
    ├── node01 (192.168.178.25)
    │   └── Docker Engine
    │
    └── node02 (192.168.178.27)
        └── Docker Engine
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

## Current Services

| Host | Purpose |
|--------|----------|
| mgmt01 | SSH, Ansible, Git, Nginx |
| node01 | Docker Container Host |
| node02 | Docker Container Host |

---

## Future Expansion

Planned additions:

- Prometheus monitoring
- Grafana dashboards
- Wazuh security monitoring
- Centralized logging
- Docker Compose deployments
- Kubernetes evaluation
- CI/CD pipelines
