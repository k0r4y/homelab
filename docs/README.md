## Current Infrastructure

### Hypervisor

- Windows Host running Hyper-V

### Management Node

- mgmt01 (192.168.178.24)
  - SSH management
  - Ansible control node
  - Git repository host
  - Nginx reverse proxy

### Managed Nodes

- node01 (192.168.178.25)
  - Container Host
  - Managed via Ansible

- node02 (192.168.178.27)
  - Container Host
  - Managed via Ansible

### Architecture

```text
Windows Host
│
├─ Hyper-V
│   │
│   ├─ mgmt01 (192.168.178.24)
│   │   ├─ SSH Management
│   │   ├─ Ansible Control Node
│   │   ├─ Git Repository
│   │   └─ Nginx Reverse Proxy
│   │
│   ├─ node01 (192.168.178.25)
│   │   └─ Docker Engine
│   │
│   └─ node02 (192.168.178.27)
│       └─ Docker Engine
│
└─ Browser
    ├─ http://192.168.178.24/node01/
    └─ http://192.168.178.24/node02/
```

### Service Access

- http://192.168.178.24/node01/
- http://192.168.178.24/node02/
