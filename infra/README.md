# Development setup

Nix has to be installed and flakes support enabled. 
No other tools are needed, `nix` is going to provide everything.  
To start build and start the dev shell, run:

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
 
