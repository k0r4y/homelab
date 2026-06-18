# SSH Agent Setup for mgmt01

To support Ansible automation, SSH agent must be running and the key loaded.

## Steps

Start agent:
```
eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519
```

eval "$(ssh-agent -s)" starts the SSH agent and connects your current terminal session to it.




=======
## SSH Authentication Requirement

The control node (mgmt01) requires an active SSH agent with the private key loaded.

Before running Ansible playbooks:

- Ensure SSH agent is running
- Ensure key is loaded using `ssh-add ~/.ssh/id_ed25519`

Without this, Ansible authentication will fail with SSH permission errors.

