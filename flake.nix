{
  description = "Root flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            excludes = ["www/themes/tabi"];
            hooks = {
              alejandra.enable = true;

              ruff-format = {
                enable = true;
                package = pkgs.ruff;
                name = "ruff-format";
                entry = "''${pkgs.ruff}/bin/ruff format";
                language = "system";
                pass_filenames = false;
              };

              ruff-check = {
                enable = true;
                package = pkgs.ruff;
                name = "ruff-check";
                entry = "''${pkgs.ruff}/bin/ruff check --fix";
                language = "system";
                pass_filenames = false;
              };

              # blacken-docs = {
              #   enable = true;
              #   package = pkgs.blacken-docs;
              #   name = "blacken-docs";
              #   entry = "''${pkgs.blacken-docs}/bin/blacken-docs";
              #   files = "\\.(md)$";
              #   language = "system";
              # };

              tofu-fmt = {
                enable = true;
                package = pkgs.opentofu;
                name = "tofu-fmt";
                entry = "''${pkgs.opentofu}/bin/tofu fmt";
                files = "^www\/content\/.*.(tf|hcl)$";
                language = "system";
              };

              # lock-www = {
              #   enable = true;
              #   package = pkgs.nix;
              #   name = "lock-www";
              #   entry = "''${pkgs.nix}/bin/nix --extra-experimental-features 'nix-command flakes' flake update --flake ./infra website";
              #   pass_filenames = false;
              #   language = "system";
              # };
            };
          };
        };

        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages ++ [pkgs.blacken-docs];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "root";
          src = ./.;
          dontBuild = true;
        };
      }
    );
}
