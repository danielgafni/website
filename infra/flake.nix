# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, ... }:
    let
      # The system we are building for. It will not work on other systems.
      # One might use flake-utils to make it work on other systems.
      system = "x86_64-linux";
      
      # Import the Nix packages from nixpkgs
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Define a formatter package for the system to enable `nix fmt`
      formatter.${system} = pkgs.nixpkgs-fmt;

      # NixOS configuration for the 'website' system
      nixosConfigurations.website = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko  # Include disko module
          ./configuration.nix       # Include custom configuration
        ];
      };

      # Development shell environment
      # It will include the packages specified in the buildInputs attribute
      # once the shell is entered using `nix develop` or direnv integration.
      devShell.${system} = pkgs.mkShell {
        buildInputs = with pkgs; [
          opentofu  # provisioning tool for the OpenTofu project
          sops
        ];
        shellHook = ''
          $SHELL
        '';
      };
    };
}
