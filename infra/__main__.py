"""Cloudflare Pages project and DNS for gafni.dev.

The static site is built with Nix and uploaded via `wrangler pages deploy`
(see the justfile), so the Pages project is a direct-upload project with no
build config or git source.
"""

import pulumi
import pulumi_cloudflare as cloudflare

config = pulumi.Config()
account_id = config.require("accountId")
zone_id = config.require("zoneId")

project = cloudflare.PagesProject(
    "website",
    account_id=account_id,
    name="gafni-dev",
    production_branch="master",
)

# Attach the apex domain to the Pages project.
cloudflare.PagesDomain(
    "website",
    account_id=account_id,
    project_name=project.name,
    name="gafni.dev",
)

# Point the apex at the Pages project. CNAME flattening handles the apex; the
# record stays proxied so Cloudflare fronts the Pages deployment. ttl=1 means
# "automatic", required for proxied records.
cloudflare.DnsRecord(
    "website",
    zone_id=zone_id,
    name="gafni.dev",
    type="CNAME",
    content=project.subdomain,
    proxied=True,
    ttl=1,
)

pulumi.export("pages_subdomain", project.subdomain)
