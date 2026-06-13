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
  WireGuard address as `10.0.0.<id>/32`. `mdune` (`vp0dune`, `id = 3`) is the
  WireGuard **hub** and the consul/nomad/vault **server**.
- `vp0dune` is intentionally in *two* inventory groups: `mdune` (hub/server
  role) and `vdune` → `clients` (it's also a normal spoke/client). Any play
  that targets `clients` and writes a host-specific config file
  (`/etc/wireguard/dune.conf`, `/etc/consul.d/consul.hcl`,
  `/etc/nomad.d/nomad.hcl`, etc.) **must** exclude `mdune` — i.e. use
  `hosts: "clients:!mdune"` — otherwise the spoke/client config silently
  overwrites the hub/server config rendered by the `mdune` play that ran
  earlier in the same run. (`basebook/wireguard/spoke.yaml`'s "Create wg
  spokes" play and `basebook/services.yaml`'s "Create dune services" play
  both do this.) `dunebook/mdune.yaml` is the sole owner of vp0dune's wg hub,
  consul/nomad server, and vault config.
- `dunebook/mdune.yaml` notifies `Restart consul` / `Restart nomad` handlers
  whenever the server config templates change, so a stale client config
  written by a previous `base-services` run gets reloaded with the correct
  server config (`server = true`, `bootstrap_expect = 1`) instead of leaving
  the daemon running with whatever config it last started with.
- Vault is installed and configured (group/user, binary, `/etc/vault.d`,
  systemd unit) on `mdune` but **not started automatically** — vault needs to
  be initialized/unsealed manually before enabling the service
  (`systemctl enable --now vault` once `vault operator init`/`unseal` is
  done).

## Commands Needed

- `(crontab -l 2>/dev/null; echo "0 */8 * * * echo \"ssh \$(sudo systemctl restart ssh) restarted => \$(date)\" >> ~/ssh-restart.log") | crontab -`
