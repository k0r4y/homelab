# Docker Deployment

## Overview

Docker Engine is deployed and maintained through Ansible.

## Deployment

Run the playbook:

```bash
ansible-playbook -i inventories/hosts docker.yml
```

## Installed Components

- Docker Engine
- Docker CLI
- containerd
- Docker Compose Plugin
- Docker Buildx Plugin

## Managed Hosts

- node01
- node02

## Verification

Check Docker version:

```bash
docker --version
```

Check running containers:

```bash
docker ps
```

Verify on all nodes through Ansible:

```bash
ansible all -m shell -a "docker --version"
```
