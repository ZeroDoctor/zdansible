SHELL := /bin/bash
SSH_PORT?=2222
SSH_USER?=root

.PHONY: install
install:
	python3 -m venv venv
	. venv/bin/activate && \
	pip install passlib ansible toml

	sudo apt update
	sudo apt install software-properties-common -y
	sudo add-apt-repository --yes --update ppa:ansible/ansible
	sudo apt install ansible -y
	ansible --version
	ansible-playbook --version

.PHONY: provide
provide: provide-init provide-dune provide-mdune provide-adune provide-vdune provide-zdune provide-bash
	
.PHONY: provide-init
provide-init:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml init.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: provide-bash
provide-bash:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/bash-dune.yaml -e 'ansible_ssh_port=2222' && \
	popd


.PHONY: provide-dune
provide-dune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/dune.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: provide-mdune
provide-mdune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/mdune.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: provide-tdune
provide-tdune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/tdune.yaml -e 'ansible_ssh_port=2222' && \
	popd
	
.PHONY: provide-adune
provide-adune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/adune.yaml -e 'ansible_ssh_port=2222' && \
	popd
	
.PHONY: provide-vdune
provide-vdune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/vdune.yaml -e 'ansible_ssh_port=2222' && \
	popd
	
.PHONY: provide-zdune
provide-zdune:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/zdune.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: wg-server
wg-server:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml wgbook/server.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: wg-client
wg-client: wg-server
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml dunebook/client-dune.yaml -e 'ansible_ssh_port=2222' && \
	popd

.PHONY: secure
secure: secure-req secure-main

.PHONY: secure-req
secure-req:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml securebook/requirements-playbook.yml \
		-e 'ansible_ssh_port=$(SSH_PORT)' && \
		# -e 'ansible_ssh_user=$(SSH_USER)' && \
	popd

.PHONY: secure-main
secure-main:
	sleep 5 && \
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml securebook/main-playbook.yml \
		-e 'ansible_ssh_port=$(SSH_PORT)' && \
		# -e 'ansible_ssh_user=$(SSH_USER)' && \
	popd

.PHONY: vars
vars:
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-inventory --list -i .inventory.toml && \
	popd
	
.PHONY: debug
debug:
	pushd ./ansible && \
	. ../venv/bin/activate && \
	ansible-playbook -i .inventory.toml debug.yaml -e 'ansible_ssh_port=2222' && \
	popd
