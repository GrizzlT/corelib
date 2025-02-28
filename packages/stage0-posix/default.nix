let
  mkPackageSet = import ../../mk-package-set.nix;

  stage0 = mkPackageSet {
    packages = self: {
      mkMinimalPackage = import ./mk-minimal-package.nix;

      ## Stage 0 posix
      minimal-bootstrap-sources = import ./bootstrap-sources.nix;

      hex0 = import ./hex0.nix;
      mescc-tools-boot = import ./mescc-tools-boot.nix;
      mescc-tools = import ./mescc-tools;
      # mescc-tools-extra = import ./mescc-tools-extra;

      ## GCC bootstrap
    };
    lib = import ./lib;
    dependencies = {
      std = import ../stdlib;
    };
  };
in
  stage0
