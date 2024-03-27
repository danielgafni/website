{
  description = "Root flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    enable-social-media-cards-check.url = "github:boolean-option/true"; # LMAO
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    enable-social-media-cards-check,
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
            hooks = {
              alejandra.enable = true;

              "1-blacken-docs" = {
                enable = true;
                package = pkgs.blacken-docs;
                name = "blacken-docs";
                entry = "''${pkgs.blacken-docs}/bin/blacken-docs";
                files = "\\.(md)$";
                language = "system";
              };

              "2-social-media-cards" = {
                enable = enable-social-media-cards-check.value;
                name = "social-media-cards";
                entry = "env PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers} PATH=${pkgs.gnused}/bin:${pkgs.coreutils}/bin:${pkgs.mktemp}/bin:${pkgs.curl}/bin:${pkgs.bash}/bin:${pkgs.python3}/bin:${pkgs.gawk}/bin:${pkgs.shot-scraper}/bin:$PATH python3 ./www/scripts/run_in_subdirectory.py www bash ./scripts/social-cards-zola -u -o ./static/img/social_cards -b 127.0.0.1:1111";
                pass_filenames = true;
                language = "system";
                files = "^www/content/.+\.md$";
                excludes = [
                  "www/content/_index.md"
                  "www/content/pages/_index.md"
                  "www/content/pages/about.md"
                ];
                package = pkgs.bash;
                packageOverrides = {
                  playwright-driver.browsers = pkgs.playwright-driver.browsers;
                  coreutils = pkgs.coreutils;
                  gnused = pkgs.gnused;
                  mktemp = pkgs.mktemp;
                  curl = pkgs.curl;
                  gawk = pkgs.gawk;
                  shot-scraper = pkgs.shot-scraper;
                  python3 = pkgs.python3;
                };
              };

              "3-lock-www" = {
                enable = true;
                package = pkgs.nix;
                name = "lock-www";
                entry = "''${pkgs.nix}/bin/nix --extra-experimental-features 'nix-command flakes' flake lock ./infra --update-input website ";
                pass_filenames = false;
                language = "system";
              };
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
