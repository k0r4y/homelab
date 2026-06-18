# Homelab

A self-hosted DevOps learning environment running on Hyper-V.

## Goals


- Learn Ansible
- Learn Docker
- Learn Kubernetes
- Learn Azure concepts
- Build a portfolio for DevOps roles in the Netherlands

## Current Architecture
```
Windows Gaming PC
└── Hyper-V
    ├── mgmt01 (Ubuntu)
    │   ├── SSH management
    │   └── Ansible control node
    ├── node01 (Ubuntu)
    └── node02 (Ubuntu)
```
## Completed

- Installed Ubuntu management VM
- Configured SSH key authentication
- Configured Ansible
- Created Ansible role structure
- Automated baseline configuration
- Added second managed node

## Next Steps

- Docker role
- Container deployment
- Monitoring
- Kubernetes
