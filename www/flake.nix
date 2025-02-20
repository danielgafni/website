{
  description = "My website flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dagger = {
      # pin to 0.15.4 since 0.16.0 and 0.16.1 are broken
      url = "git+https://github.com/dagger/nix?ref=4247e1fcb92981bcad5fec447a2994ea29c8d344";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    dagger,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;

        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with pkgs; [zola dagger.packages.${system}.dagger];
        };

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
