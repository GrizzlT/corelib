let
  mkPackageSet = import ../../mk-package-set.nix;

  bootstrap = mkPackageSet {
    packages = self: {
      mes = import ./mes/mescc.nix;
      # mes-libc = import ./mes/libc.nix;
      # ln-boot = import ./ln-boot;
      #
      # tinycc-bootstrappable = import ./tinycc/bootstrappable.nix;
      # tinycc-mes = import ./tinycc/mes.nix;
      #
      # gnupatch = import ./gnupatch;
      # gnumake = import ./gnumake;
      #
      # coreutils = import ./coreutils;
      # bash_2_05 = import ./bash/2.nix;
      #
      # gnugrep = import ./gnugrep;
      # gnused-mes = import ./gnused/mes.nix;
      # gnutar = import ./gnutar/mes.nix;
      # gzip = import ./gzip;
      # musl11 = import ./musl/1.1.nix;
      #
      # tinycc-musl-pre = import ./tinycc/musl.nix;
      # tinycc-musl = import ./tinycc/cached-musl.nix;
    };
    lib = import ./lib;
    dependencies = {
      stage0 = import ../stage0-posix;
      std = import ../stdlib;
    };
  };
in
  bootstrap
