{
  flake,
  system,
  legacyPackages,
  ...
}: {
  default = flake.packages.${system}.clump;
  clump = legacyPackages.haskellPackages.callPackage ./clump {};
}
