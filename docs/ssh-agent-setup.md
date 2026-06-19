# SSH Agent Setup

## Overview

This homelab uses SSH key-based authentication for automated infrastructure management from `mgmt01` using Ansible.

An SSH agent is used to avoid repeatedly loading the private key during automation workflows.

---

## Architecture

```text
mgmt01 → node01
       → node02
```

All automation is executed from `mgmt01`.

---

## Purpose

The SSH agent enables:

- Passwordless Ansible execution
- Simplified SSH authentication
- Reliable automation across sessions

---

## Key Management

Private key:

```bash
~/.ssh/id_ed25519
```

Loaded into an SSH agent during login.

---

## Agent Persistence

The SSH agent is automatically restored via `.bashrc`, ensuring sessions retain authentication state.

---

## Verification

Check agent connection:

```bash
echo $SSH_AUTH_SOCK
```

Check loaded keys:

```bash
ssh-add -l
```

---

## Testing Connectivity

```bash
ssh ansible@192.168.178.25
ssh ansible@192.168.178.27
```

Both hosts should allow passwordless login.

---

## Ansible Validation

```bash
ansible all -i inventories/hosts -m ping
```

Expected:

```text
SUCCESS
```

---

## Notes

This setup is used by all Ansible automation workflows in the homelab.
