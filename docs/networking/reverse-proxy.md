# Nginx Reverse Proxy

## Purpose

Provide a single entry point for services running across multiple Docker nodes.

## Reverse Proxy Host

- mgmt01 (192.168.178.24)

## Routing

```text
/node01/ -> 192.168.178.25:8081
/node02/ -> 192.168.178.27:8082
```

## Traffic Flow

```text
Client Browser
        │
        ▼
mgmt01 (Nginx Reverse Proxy)
        │
        ├── node01 (192.168.178.25:8081)
        │
        └── node02 (192.168.178.27:8082)
```

## Firewall Configuration

Allow HTTP traffic:

```bash
sudo ufw allow 80/tcp
```

Verify firewall status:

```bash
sudo ufw status
```

## Validation

Test node01:

```bash
curl http://192.168.178.24/node01/
```

Test node02:

```bash
curl http://192.168.178.24/node02/
```

Expected result:

Both routes should return content served from their respective backend nodes.
