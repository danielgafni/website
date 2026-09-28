# Daniel Gafni's Website

Source code for my [website](https://gafni.dev)

Technologies used:
 - `nix` + [`devenv`](https://devenv.sh) - dev environment. Provides all necessary packages.
 - [`Zensical`](https://zensical.org) - static site generator from markdown
 - `Pulumi` (Python) - IaC for the Cloudflare Pages project & DNS
 - `Cloudflare Pages` - static hosting

The only tools required to build and deploy everything are [Nix](https://nixos.org/download/) and [`devenv`](https://devenv.sh/getting-started/). 

A single `devenv` shell at the repo root (run `devenv shell`, or use `direnv` for automatic activation) provides all the other tools (`pulumi`, `uv`, `wrangler`, etc.); Python packages (`zensical`, Pulumi SDK) come from PyPI via the root `uv` workspace. 

The static site is built with `zensical build` in `www/` (output in `www/site`) and uploaded to [Cloudflare Pages](https://pages.cloudflare.com/) via `wrangler`. On push to `master`, GitHub Actions builds and deploys automatically.

# File Structure

```
.
├── infra  # deployment code
├── LICENSE
└── www  # website code
```
