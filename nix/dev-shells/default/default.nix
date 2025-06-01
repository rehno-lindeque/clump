{
  mkShell,
  cabal-install,
  cabal2nix,
  clump
}:
mkShell {
  buildInputs = [
    cabal2nix
    cabal-install
  ];

  inputsFrom = [
    clump.env
  ];

  shellHook = let
     nc = "\\e[0m"; # No Color
     white = "\\e[1;37m";
   in ''
     clear -x
     printf "${white}"
     echo "-----------------------"
     echo "Development environment"
     echo "-----------------------"
     printf "${nc}"
     echo
     '';
}
