{
  description = "My website flake";

  # The dev shell lives in devenv.nix; this flake only builds the site so that
  # `nix build ./www` produces the deployable `zola build` output.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;

        packages.default = pkgs.stdenv.mkDerivation {
          name = "website";
          src = ./.;
          dontBuild = true;
          nativeBuildInputs = with pkgs; [
            zola
          ];
          checkPhase = ''
            zola check
          '';
          installPhase = ''
            zola build --base-url https://gafni.dev -o "$out"
          '';
        };
      }
    );
}
