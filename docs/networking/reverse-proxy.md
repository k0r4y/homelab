# Nginx Reverse Proxy

## Purpose

Provide a single entry point on `mgmt01` for accessing services running across the homelab (monitoring stack, future Wazuh dashboard, etc.).

---

## Reverse Proxy Host

- **mgmt01** (192.168.178.24)

## Current Routing

| Path              | Backend                        | Purpose |
|-------------------|--------------------------------|---------|
| `/grafana/`       | `localhost:3000`               | Grafana UI |
| `/prometheus/`    | `localhost:9090`               | Prometheus UI |

---

## Configuration

Nginx configuration is managed via the `reverse_proxy` Ansible role.

Location: `ansible/roles/reverse_proxy/templates/nginx.conf.j2`

---

## Deployment

Apply changes with:

    ansible-playbook \
      -i ansible/inventories/hosts \
      ansible/playbooks/mgmt01.yml \
      --limit mgmt01

---

## Future Enhancements

- `/wazuh/` → node03 Wazuh Dashboard
- `/k8s/` or hostname-based routing for Kubernetes Ingress
- TLS termination with Let's Encrypt / cert-manager

---

## Validation

From any browser or curl:

    curl -I http://192.168.178.24/grafana/
    curl -I http://192.168.178.24/prometheus/

Expected: HTTP 200 responses.

---

## Firewall

Ensure HTTP traffic is allowed:

    sudo ufw allow 80/tcp
    sudo ufw status

---

This reverse proxy keeps the homelab accessible through a clean, centralized URL structure.
