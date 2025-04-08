let
  mkPackageSet = import ../../mk-package-set.nix;

  bootstrap = mkPackageSet {
    packages = self: {
      mes = import ./mes;
      mes-libc = import ./mes/libc.nix;
      ln-boot = import ./ln-boot;

      tinycc-bootstrappable = import ./tinycc/bootstrappable.nix;
    };
    lib = import ./lib;
    dependencies = {
      stage0 = import ../stage0-posix;
      std = import ../stdlib;
    };
  };
in
  bootstrap
