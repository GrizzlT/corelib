let
  mkPackageSet = import ../../mk-package-set.nix;

  stage0 = mkPackageSet {
    packages = self: {
      mkMinimalPackage = import ./mk-minimal-package.nix;
      minimal-bootstrap-sources = import ./bootstrap-sources.nix;

      hex0 = import ./hex0.nix;
    };
    lib = import ./lib;
    dependencies = {
      std = import ../stdlib;
    };
  };
in
  stage0
