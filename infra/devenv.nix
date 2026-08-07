{pkgs, ...}: {
  # Tooling for provisioning Cloudflare with Pulumi (Python, managed by uv)
  # and deploying the Nix-built static site to Cloudflare Pages (wrangler).
  packages = with pkgs; [
    pulumi-bin
    uv
    just
    wrangler
  ];
}
