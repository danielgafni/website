{pkgs, ...}: {
  packages = with pkgs; [
    # prek runs the git hooks (a faster drop-in for pre-commit); blacken-docs is
    # not tied to a specific hook.
    prek
    blacken-docs
    # Tooling for provisioning Cloudflare with Pulumi and deploying the static
    # site to Cloudflare Pages (wrangler).
    pulumi-bin
    just
    wrangler
  ];

  # Python packages (zensical for www/, pulumi for infra/) come from PyPI via
  # the uv workspace in pyproject.toml.
  languages.python = {
    enable = true;
    venv.enable = true;
    uv = {
      enable = true;
      sync = {
        enable = true;
        allPackages = true;
      };
    };
  };

  git-hooks = {
    hooks = {
      alejandra.enable = true;

      ruff-format = {
        enable = true;
        name = "ruff-format";
        entry = "${pkgs.ruff}/bin/ruff format";
        language = "system";
        pass_filenames = false;
      };

      ruff-check = {
        enable = true;
        name = "ruff-check";
        entry = "${pkgs.ruff}/bin/ruff check --fix";
        language = "system";
        pass_filenames = false;
      };

      tofu-fmt = {
        enable = true;
        name = "tofu-fmt";
        entry = "${pkgs.opentofu}/bin/tofu fmt";
        files = "^www/snippets/.*.(tf|hcl)$";
        language = "system";
      };
    };
  };
}
