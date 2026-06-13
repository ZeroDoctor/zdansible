# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ansible playbooks that provision and configure a personal fleet of "dune" hosts
(`mdune`, `adune`, `tdune`, `vdune`, `zdune`, plus a vps `zpldune`/`zdune`)
connected via WireGuard, running Consul + Nomad (+ Vault on the hub) for
service discovery and orchestration.

## Setup & commands

All `ansible-playbook` invocations go through `make` targets (defined in
`Makefile`) and run inside `venv/bin/activate`. Inventory is `.inventory.toml`
(TOML inventory plugin, gitignored — not present by default).

```sh
make install        # create venv, install ansible/ansible-lint/passlib/toml, install ansible itself
```

Standard full run, in order:

```sh
make secure base provide
```

- `secure` = `secure-req` (vendored requirements playbook) + `secure-main`
  (vendored hardening playbook) from `securebook/`.
- `base` = `base-init base-network base-wg-hub base-services` — OS packages,
  firewall/network rules, WireGuard hub, then Consul/Nomad client services.
- `provide` = `provide-mdune provide-adune provide-vdune provide-zdune` (run
  in that order — `mdune` must go first).

Individual targets (each runs `ansible-playbook -i .inventory.toml ... -e 'ansible_ssh_port=$(SSH_PORT)'`,
override with `SSH_PORT=`):

- `base-init`, `base-network`, `base-wg-hub`, `base-wg-spoke`,
  `base-wg-hub-test`, `base-services`
- `provide-mdune`, `provide-tdune`, `provide-adune`, `provide-vdune`, `provide-zdune`

Helpers:

```sh
make vars   # ansible-inventory --list -i .inventory.toml
make debug  # run debug.yaml, dumps ansible_facts for all hosts
```

To target a single host or run with extra verbosity, append standard
`ansible-playbook` flags (`--limit`, `-vvv`, `--check`) to the underlying
command — the `make` targets don't expose these directly, so invoke
`ansible-playbook -i .inventory.toml <playbook> -e 'ansible_ssh_port=...'`
manually when needed.

## Inventory model (`.inventory.toml`)

- `[ungrouped.hosts]` is the source of truth for every host: maps an SSH
  connection string to `{ user, ip, host, id, extra_users? }`.
- `id` (1-254) determines that host's WireGuard address: `10.0.0.<id>/32`.
- Each "dune" group (`adune`, `mdune`, `tdune`, `vdune`, `zdune`) has its own
  `[<group>.vars]` (sets `ansible_ssh_user`) and `[<group>.hosts]`.
- `clients` = `adune + tdune + vdune + zdune`. `all` = `clients + mdune`.
- `net_longview`, `net_houston`, `net_vps` group hosts by physical
  network/location for firewall rules in `basebook/network.yaml`.
- `vp0dune` (id=3) is deliberately in **both** `mdune` (hub/server role) and
  `vdune` → `clients` (spoke/client role).

## Architecture / playbook layering

```
basebook/secure-req.yaml / secure-main.yaml  -> securebook/ (vendored hardening, see securebook/README.md)
basebook/init.yaml      -> OS packages, podman, consul/nomad apt/binary install
basebook/network.yaml   -> ufw rules between net_houston/net_longview/net_vps, dune bashrc
basebook/wireguard/
  setup.yaml  -> per-host wg keypair generation (wg-gen.sh)
  hub.yaml    -> renders hub.conf.j2 for mdune, brings up `dune` wg interface
  spoke.yaml  -> imports hub.yaml, then renders spoke.conf.j2 for clients:!mdune
basebook/services.yaml -> imports wireguard/spoke.yaml, then consul-client.hcl.j2 /
                           nomad-client.hcl.j2 for clients:!mdune
dunebook/mdune.yaml -> hub-only: vault install/config (not auto-started),
                       consul/nomad SERVER config, dnsmasq + resolv.conf for
                       *.service.consul DNS, clones zdnomad/zdmigration repos
dunebook/{adune,tdune,vdune,zdune}.yaml -> per-host volume/mount/service setup
```

Key invariant: **any play targeting `clients` that writes a host config file**
(`/etc/wireguard/dune.conf`, `/etc/consul.d/consul.hcl`, `/etc/nomad.d/nomad.hcl`)
**must use `hosts: "clients:!mdune"`**. `vp0dune`/`mdune` is the sole owner of
its own hub/server configs (rendered by `dunebook/mdune.yaml`); letting a
generic spoke/client play touch it overwrites the server config with a client
one. `dunebook/mdune.yaml` notifies `Restart consul`/`Restart nomad` to fix
exactly this if a stale client config was written by an earlier `base-services`
run.

Vault on `mdune` is installed/configured but **never auto-started** — requires
manual `vault operator init` / `unseal` before `systemctl enable --now vault`.

## Variables

- `vars/vars.yaml` — non-secret shared vars.
- `vars/vars.secrets.yaml` — secrets (git tokens, db creds, wg keys, etc.),
  loaded by nearly every playbook via `vars_files`. Treat as sensitive;
  templates rely on `no_log: true` on tasks that render it.

## Templates

Jinja2 templates live next to the playbook that uses them
(`basebook/wireguard/templates/`, `basebook/templates/`,
`dunebook/templates/`) — check both the `.j2` and the task's `dest:` to see
where a rendered config ends up on the target host.
