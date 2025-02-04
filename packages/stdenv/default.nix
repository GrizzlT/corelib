let
  mkPackageSet = import ../../mk-package-set.nix;

  stdenv = mkPackageSet {
    packages = self: {
      bash = import ./bash.nix;
      stdenv = import ./stdenv;
      mkStdenv = import ./stdenv/generic;
    };
    lib = import ./lib.nix;
  };
in
  stdenv
