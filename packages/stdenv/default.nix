let
  mkPackageSet = import ../../mk-package-set.nix;

  stdenv = mkPackageSet {
    /*
      Takes in a fixpoint to allow for future expansion (e.g. overriding recipes)
    */
    packages = self: {
      bash = import ./bash.nix;
      stdenv = import ./stdenv;
      mkStdenv = import ./stdenv/generic;

      mkAutoTools = import ./autotools.nix;

      hello = import ./hello.nix;
    };
    lib = import ./lib;
  };
in
  stdenv
