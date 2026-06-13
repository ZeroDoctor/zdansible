# zdansible

## Run Playbook

```sh
make secure base provide
```

Run in this order. `provide` runs `provide-mdune` first, then
`provide-adune provide-vdune provide-zdune` — mdune must come first since it
hosts the wg hub, the consul/nomad servers, and the dnsmasq resolver that the
other hosts rely on for `*.service.consul` DNS.

## Architecture notes

- Inventory IDs (`.inventory.toml`, `[ungrouped.hosts]`) assign each host's
  WireGuard address as `10.0.0.<id>/32`. WireGuard is a **full mesh**: every
  host in `groups['all']` gets a `/32` peer entry for every other host, each
  using its own locally-generated keypair (`basebook/wireguard/setup.yaml`,
  rendered by `basebook/wireguard/templates/dune.conf.j2`).
- `mdune` is the consul/nomad-server + vault group, and is **dynamically
  sized** — `bootstrap_expect` for consul and nomad, the consul `retry_join`
  lists, the vault HA backend, and the client `/etc/resolv.conf` nameservers
  are all derived from `groups['mdune'] | length` / `groups['mdune']`. To add
  an HA member, add it to `.inventory.toml` (`[ungrouped.hosts]` with a unique
  `id`, plus `[mdune.hosts]`) and re-run `make base provide`. Because the wg
  mesh peer list depends on every host's generated pubkey, adding/removing a
  host requires a full `make base` run (not just `provide-mdune`) so
  `setup.yaml` generates keys for the new host before everyone re-templates.
- `vp0dune` is intentionally in *two* inventory groups: `mdune` (server role)
  and `vdune` → `clients` (it's also a normal spoke/client). Any play that
  targets `clients` and writes a host-specific config file
  (`/etc/wireguard/dune.conf`, `/etc/consul.d/consul.hcl`,
  `/etc/nomad.d/nomad.hcl`, etc.) **must** exclude `mdune` — i.e. use
  `hosts: "clients:!mdune"` — otherwise the spoke/client config silently
  overwrites the server config rendered by the `mdune` play that runs later
  in the same run. (`basebook/wireguard/spoke.yaml`'s "Create wg spokes" play
  and `basebook/services.yaml`'s "Create dune services" play both do this.)
  `basebook/services.yaml`'s "Create mdune server services" play (runs after
  "Create dune services") is the sole owner of an `mdune` host's
  `/etc/consul.d/consul.hcl` and `/etc/nomad.d/nomad.hcl` — it runs as part of
  `base-services`/`make base`, so a plain `make base` always leaves `mdune`
  hosts with the correct server config (`server = true`, dynamic
  `bootstrap_expect`) without needing `provide-mdune`. `dunebook/mdune.yaml`
  (`provide-mdune`) owns the rest of an `mdune` host's setup: wg config,
  vault config, dnsmasq resolver, and the zdnomad/migration tooling.
- Vault is installed and configured (group/user, binary, `/etc/vault.d`,
  systemd unit) on each `mdune` host but **not started automatically** —
  vault needs to be initialized/unsealed manually before enabling the service
  (`systemctl enable --now vault` once `vault operator init`/`unseal` is
  done). Vault HA is backed by the shared `postgresql` storage
  (`ha_enabled = "true"`) plus a per-host `cluster_addr` for active/standby
  request forwarding.

## Commands Needed

- `(crontab -l 2>/dev/null; echo "0 */8 * * * echo \"ssh \$(sudo systemctl restart ssh) restarted => \$(date)\" >> ~/ssh-restart.log") | crontab -`
