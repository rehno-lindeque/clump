{ mkDerivation, base, bytestring, lib }:
mkDerivation {
  pname = "clump";
  version = "0.1.0.0";
  src = lib.fileset.toSource {
    root = ../../..;
    fileset = lib.fileset.unions [
      ../../../src
      ../../../clump.cabal
      ../../../LICENSE
    ];
  };
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base bytestring ];
  description = "Buffer stdin until idle, then flush with optional prefix/suffix";
  license = lib.licenses.asl20;
  mainProgram = "clump";
}

