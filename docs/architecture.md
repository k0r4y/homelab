# Architecture

## Overview

This document describes the physical and logical architecture of the SOC homelab environment.  
The infrastructure runs on Hyper-V and is fully automated using Ansible with centralized monitoring.

---

## 1. Physical Infrastructure

### Hyper-V Layout

    Windows Host (Gaming PC)
    └── Hyper-V Virtual Switch (External)
        ├── mgmt01 (192.168.178.24)
        ├── node01 (192.168.178.25)
        └── node02 (192.168.178.27)

---

## 2. Logical Architecture

The environment is structured into three layers:

- Management Layer (mgmt01)
- Compute Layer (node01, node02)
- Observability Layer (Prometheus + Grafana)

---

## 3. Node Roles

### mgmt01 (192.168.178.24)

- Ansible control node
- Docker host
- Prometheus
- Grafana
- cAdvisor
- Nginx reverse proxy

### node01 (192.168.178.25)

- Docker Engine
- Node Exporter

### node02 (192.168.178.27)

- Docker Engine
- Node Exporter

---

## 4. Management Flow

    Administrator
        │
        ▼
    mgmt01 (Ansible Control Node)
        │
        ├── SSH → node01
        └── SSH → node02

---

## 5. Automation Flow (Ansible)

    Ansible Playbooks (mgmt01)
            │
            ├── Install Docker
            ├── Deploy Monitoring Stack
            ├── Configure Reverse Proxy
            ├── System Configuration
            │
            ├── node01
            └── node02

---

## 6. Container Architecture

    mgmt01
     ├── Prometheus
     ├── Grafana
     └── cAdvisor

    node01
     ├── Docker workloads
     └── Node Exporter

    node02
     ├── Docker workloads
     └── Node Exporter

---

## 7. Network Architecture

    Client Browser
          │
          ▼
    mgmt01 (192.168.178.24)
          │
          ▼
    Nginx Reverse Proxy
          │
          ├── /grafana    → localhost:3000
          ├── /prometheus → localhost:9090
          ├── /node01     → 192.168.178.25
          └── /node02     → 192.168.178.27

---

## 8. Monitoring Flow

node01 (192.168.178.25)
    └── Node Exporter (:9100)
            │
node02 (192.168.178.27)
    └── Node Exporter (:9100)
            │
            ▼
      Prometheus (:9090)
            │
            │ (HTTP query API :9090)
            ▼
     Grafana (:3000)

---

## 9. Security Model

- SSH key authentication only
- Dedicated `ansible` user
- Passwordless sudo for automation
- Secrets stored in Ansible Vault
- No direct exposure of worker nodes

---

## 10. Summary

This architecture provides:

- Fully automated infrastructure (Ansible)
- Centralized control plane (mgmt01)
- Scalable worker nodes
- Unified monitoring stack
- Reverse proxy entry layer
- Rebuildable infrastructure-as-code design
