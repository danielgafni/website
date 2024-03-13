{
  description = "My website flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        {
          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [
              zola
            ];
            shellHook = ''
              $SHELL
            '';
          };

          packages.default = pkgs.stdenv.mkDerivation {
            name = "website";
            src = ./.;
            dontBuild = true;
            nativeBuildInputs = with pkgs; [ zola ];
            checkPhase = ''
              zola check  
            '';
            installPhase = ''
              zola build -o "$out"
            '';
          };    
        }
      );
}

