{pkgs, ...}: {
  # prek runs the git hooks (a faster drop-in for pre-commit); blacken-docs is
  # not tied to a specific hook.
  packages = [pkgs.prek pkgs.blacken-docs];

  git-hooks = {
    excludes = ["www/themes/tabi"];

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
        files = "^www/content/.*.(tf|hcl)$";
        language = "system";
      };
    };
  };
}
