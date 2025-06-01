{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;

    supportedSystems = let
      system = lib.genAttrs lib.platforms.all (system: system);
    in [
      system.x86_64-linux
      system.aarch64-linux
      system.x86_64-darwin
      system.aarch64-darwin
    ];
    legacyPackages = lib.genAttrs supportedSystems (
      system:
        import nixpkgs {inherit system;}
    );
  in {
    devShells = lib.genAttrs supportedSystems (system: {
      default = legacyPackages.${system}.callPackage ./nix/dev-shells/default {
        inherit (self.packages.${system}) clump;
      };
    });

    formatter = lib.genAttrs supportedSystems (system: legacyPackages.${system}.alejandra);

    packages = lib.genAttrs supportedSystems (
      system:
        import ./nix/packages {
          flake = self;
          legacyPackages = legacyPackages.${system};
          inherit lib system;
        }
    );
  };
}
