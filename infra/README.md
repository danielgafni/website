# Development setup

Nix and [`devenv`](https://devenv.sh) have to be installed (flakes support enabled).

Entering the development shell (`direnv` can be used to do it automatically):

```shell
devenv shell
```

This provides `pulumi`, `uv`, `wrangler` and `just`.

# First-time setup

Log in to the `danielgafni` Pulumi Cloud organization and create the stack:

```shell
pulumi login
pulumi stack init danielgafni/website/prod
```

Configure the Cloudflare credentials and identifiers (the API token needs
Account → Cloudflare Pages: Edit and Zone → DNS: Edit):

```shell
pulumi config set --secret cloudflare:apiToken <token>
pulumi config set accountId <cloudflare-account-id>
pulumi config set zoneId <gafni.dev-zone-id>
```

# Infrastructure deployment

Provision / update the Cloudflare Pages project and DNS:

```shell
just deploy-infra   # pulumi up --stack danielgafni/website/prod
```

# Content deployment

Build the site with Nix and upload it to Cloudflare Pages:

```shell
just deploy         # nix build ../www && wrangler pages deploy result
```

`wrangler` reads `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from the
environment (or use `wrangler login`). On push to `master`, GitHub Actions runs
this content deploy automatically.

# File Structure

```
.
├── Pulumi.yaml       # Pulumi project (Python, uv toolchain)
├── __main__.py       # Cloudflare Pages project + DNS
├── pyproject.toml    # Python dependencies (pulumi, pulumi-cloudflare)
├── devenv.nix        # dev shell (pulumi, uv, wrangler, just)
├── devenv.yaml       # devenv inputs
├── justfile          # common CLI commands
└── README.md
```
