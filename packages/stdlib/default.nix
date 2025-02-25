let
  mkPackageSet = import ../../mk-package-set.nix;

  stdlib = mkPackageSet {
    lib = lib: let
      callLibs = file: import file lib;
    in {

      # often used, or depending on very little
      trivial = callLibs ./trivial.nix;
      fixed-points = callLibs ./fixed-points.nix;

      # datatypes
      attrsets = callLibs ./attrsets.nix;
      lists = callLibs ./lists.nix;
      strings = callLibs ./strings.nix;

      # packaging
      derivations = callLibs ./derivations.nix;
      versions = callLibs ./versions.nix;
      # TODO: add derivation fixpoint
      # TODO: add meta checks

      # constants
      # TODO: add licenses?

      # misc
      asserts = callLibs ./asserts.nix;
      # TODO: add generators?

      # Eval-time filesystem handling
      # TODO: necessary?
      # path = callLibs ./path;
    };
  };
in stdlib
