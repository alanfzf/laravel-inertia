{
  description = "Multi Architecture Nix Flake for PHP development";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages = import ./nix/packages.nix {
          inherit
            pkgs
            self
            system
            ;
        };

        devShell = import ./nix/devshell.nix {
          inherit pkgs;
        };
      in
      {
        packages = packages;
        devShells.default = devShell;
      }
    );
}
