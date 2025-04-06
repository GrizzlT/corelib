let
  mkPackageSet = import ../../mk-package-set.nix;

  bootstrap = mkPackageSet {
    packages = self: {
      mes = import ./mes;
    };
    dependencies = {
      stage0 = import ../stage0-posix;
      std = import ../stdlib;
    };
  };
in
  bootstrap
