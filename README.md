# Daniel Gafni's Website

Source code for my [website](https://gafni.dev)

Technologies used:
 - `nix` - dev environment, packaging, deployment. Provides all necessary packages. 
 - `zola` - static website generator from markdown
 - `OpenTofu` - IaC for Hetzner & Cloudflare
 - `Hetzner Cloud` - VM hosting
 - `Cloudflare` - caching & proxy

The only required tool is [Nix](https://nixos.org/download/) (flakes have to be enabled) 

# File Structure

```
 .
├──  infra  # deployment code
├──  LICENSE
└──  www  # website code
```

