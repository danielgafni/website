# flake.nix
{

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    website = {
      url = "path:../www"; # Points to the flake in the website directory
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, website, ... }@attrs:
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
        specialArgs = attrs;
        modules = [
          disko.nixosModules.disko # Include disko module
          ./configuration.nix # Include custom configuration
        ];
      };

      # Development shell environment
      # It will include the packages specified in the buildInputs attribute
      # once the shell is entered using `nix develop` or direnv integration.
      devShell.${system} = pkgs.mkShell {
        buildInputs = with pkgs; [
          opentofu # provisioning tool for the OpenTofu project
          sops
          bind
          just
          nixos-rebuild
        ];
        shellHook = ''
          $SHELL
        '';
      };
    };
}
