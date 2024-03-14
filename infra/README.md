# Development setup

Nix has to be installed and flakes support enabled.

Entering the development shell (`direnv` and `lorri` can be used to do it automatically):

```shell
nix develop
```

# Infrastructure deployment

```shell
tofu apply
```

## Editing secrets

```shell
sops secrets.enc.json
```

# Website deployment

```
just nixos-rebuild
```

# File Structure

```
 .
├──  configuration.nix  # NixOS config (packages + services + website)
├──  disk-config.nix  # disk config
├──  flake.lock
├──  flake.nix  # main NixOS host config entrypoint (combines all other .nix configs)
├──  justfile  # common CLI commands
├── 󱁢 main.tf  # hetzner & cloudflare setup
├──  README.md
├──  secrets.enc.json  # secrets like API keys encoded by sops
```
