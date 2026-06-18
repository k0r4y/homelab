# SSH Agent Setup for mgmt01

To support Ansible automation, SSH agent must be running and the key loaded.

## Steps

Start agent:
```
eval "$(ssh-agent -s)"

ssh-add ~/.ssh/id_ed25519
```

eval "$(ssh-agent -s)" starts the SSH agent and connects your current terminal session to it.



