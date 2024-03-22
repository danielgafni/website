{
  description = "My website flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;

        devShell = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with pkgs; [zola];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "website";
          src = ./.;
          dontBuild = true;
          nativeBuildInputs = with pkgs; [zola];
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
