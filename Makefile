# SOC-Lab-as-Code Control Panel
# Location: ~/homelab/

# Variables
INVENTORY = ansible/inventories/hosts
PLAYBOOKS = ansible/playbooks
VAULT_PASS = ~/.vault_pass

.PHONY: help status deploy-mgmt deploy-wazuh up

help:
	@echo "Available Commands:"
	@echo "  status        - Ping all nodes"
	@echo "  deploy-mgmt   - Run mgmt01 playbook"
	@echo "  deploy-wazuh  - Run wazuh playbook"
	@echo "  up            - Provision gateway (via Vagrant)"

status:
	ansible all -i $(INVENTORY) -m ping --vault-password-file $(VAULT_PASS)

deploy-mgmt:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOKS)/mgmt01.yml --vault-password-file $(VAULT_PASS)

deploy-wazuh:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOKS)/wazuh.yml --vault-password-file $(VAULT_PASS)

up:
	vagrant up
