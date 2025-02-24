let
  mkPackageSet = import ../../mk-package-set.nix;

  stdlib = mkPackageSet {
    lib = lib: let
      callLibs = file: import file lib;
    in {

      # often used, or depending on very little
      trivial = callLibs ./trivial.nix;

      # datatypes
      strings = callLibs ./strings.nix;
    };
  };
in stdlib
