# Daniel Gafni's Website

Source code for my [website](https://gafni.dev)

Technologies used:
 - `nix` + [`devenv`](https://devenv.sh) - dev environment, packaging, deployment. Provides all necessary packages. 
 - `zola` - static website generator from markdown
 - `Pulumi` (Python) - IaC for the Cloudflare Pages project & DNS
 - `Cloudflare Pages` - static hosting

The only tools required to build and deploy everything are [Nix](https://nixos.org/download/) (flakes have to be enabled) and [`devenv`](https://devenv.sh/getting-started/). 

`devenv` provides the dev shells (run `devenv shell`, or use `direnv` for automatic activation) with all the other tools (`pulumi`, `uv`, `zola`, `wrangler`, etc.). 

The static site is built with Nix (`nix build ./www` produces the `zola build` output) and uploaded to [Cloudflare Pages](https://pages.cloudflare.com/) via `wrangler`. On push to `master`, GitHub Actions builds and deploys automatically.

# File Structure

```
.
├── infra  # deployment code
├── LICENSE
└── www  # website code
```

# Acknowledgements

`Nix` & `OpenTofu` usage is inspired by the excellent [series](https://flakm.com/series/simple-personal-blog/) of posts by @flakm
