SHELL := /bin/bash
SSH_PORT?=2222
SSH_USER?=root

.PHONY: install
install:
	python3 -m venv venv
	. venv/bin/activate && \
	pip install passlib ansible ansible-lint toml

	sudo apt update
	sudo apt install software-properties-common wireguard-tools -y
	sudo add-apt-repository --yes --update ppa:ansible/ansible
	sudo apt install ansible -y
	ansible --version
	ansible-playbook --version

# ── Secure (vendored) ──────────────────────────────────────────────────────────

.PHONY: secure
secure: secure-req secure-main

.PHONY: secure-req
secure-req:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/secure-req.yaml

.PHONY: secure-main
secure-main:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/secure-main.yaml

# ── Base / Generic ─────────────────────────────────────────────────────────────

.PHONY: base
base: base-init base-network base-wg-hub base-services

.PHONY: base-init
base-init:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/init.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: base-network
base-network:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/network.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: base-wg-hub
base-wg-hub:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/wireguard/hub.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: base-wg-spoke
base-wg-spoke:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/wireguard/spoke.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: base-wg-hub-test
base-wg-hub-test:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/wireguard/hub.test.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: base-services
base-services: base-wg-hub
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/services.yaml \
		-e 'ssh_port=$(SSH_PORT)'

# ── Specific / Per-role ────────────────────────────────────────────────────────

.PHONY: provide
provide: provide-mdune provide-adune provide-vdune provide-zdune provide-cdune

.PHONY: provide-mdune
provide-mdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/mdune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: provide-tdune
provide-tdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/tdune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: provide-adune
provide-adune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/adune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: provide-vdune
provide-vdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/vdune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: provide-zdune
provide-zdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/zdune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: provide-cdune
provide-cdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/cdune.yaml \
		-e 'ssh_port=$(SSH_PORT)'

.PHONY: bootstrap-cdune
bootstrap-cdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/bootstrap.yaml \
		-e 'ansible_ssh_port=22 ansible_ssh_user=root ansible_user=root'

# For fresh cdune machines before securebook hardens SSH to port 2222.
# detect-port auto-detects port 22 fallback; services runs without --limit
# so setup.yaml sets pubkey facts on all hosts for the hub template.
.PHONY: base-cdune
base-cdune:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/init.yaml \
		--limit cdune -e 'ssh_port=$(SSH_PORT)'
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/network.yaml \
		--limit cdune -e 'ssh_port=$(SSH_PORT)'
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml basebook/services.yaml \
		-e 'ssh_port=$(SSH_PORT)'

# ── Helpers ────────────────────────────────────────────────────────────────────

.PHONY: vars
vars:
	. venv/bin/activate && \
	ansible-inventory --list -i .inventory.toml

.PHONY: debug
debug:
	. venv/bin/activate && \
	ansible-playbook -i .inventory.toml debug.yaml \
		-e 'ssh_port=$(SSH_PORT)'
