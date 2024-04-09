# Daniel Gafni's Website

Source code for my [website](https://gafni.dev)

Technologies used:
 - `nix` - dev environment, packaging, deployment. Provides all necessary packages. 
 - `zola` - static website generator from markdown
 - `OpenTofu` - IaC for Hetzner & Cloudflare
 - `Hetzner Cloud` - VM hosting
 - `Cloudflare` - caching & proxy
 - `Prometheus` - metrics collection
 - `Grafana` - metrics visualistaion

The only tool required to build and deploy everything is [Nix](https://nixos.org/download/) (flakes have to be enabled). 

`nix` installs all the other tools (`terraform`, `zola`, etc.). 

`NixOS` is used to define the server contents. The website is served via `nginx`, which is running as a `NixOS` service, as well as `Prometheus` and `Grafana`. `Grafana` can be accessed at [grafana.gafni.dev](https://grafana.gafni.dev).

# File Structure

```
 .
├──  infra  # deployment code
├──  LICENSE
└──  www  # website code
```

# Acknowledgements

`Nix` & `OpenTofu` usage is inspired by an excellent [series](https://flakm.com/series/simple-personal-blog/) of posts by @flakm

