let
  bootstrap = {
    packages = {
      nyacc = import ./mes/nyacc.nix;
      mes-boot = import ./mes/mes-boot.nix;
      mes = import ./mes/mes.nix;
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

    lib = self': {
      self = import ./lib self';
      std = import ../stdlib self'.std;
    };

    dependencies = {
      stage0 = import ../stage0-posix;
    };
  };
in
  bootstrap
