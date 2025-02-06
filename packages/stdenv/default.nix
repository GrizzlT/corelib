let
  mkPackageSet = import ../../mk-package-set.nix;

  stdenv = mkPackageSet {
    packages = self: {
      bash = import ./bash.nix;
      stdenv = import ./stdenv;
      mkStdenv = import ./stdenv/generic;

      hello = import ./hello.nix;
    };
    lib = import ./lib.nix;
  };
in
  stdenv
