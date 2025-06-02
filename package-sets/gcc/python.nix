{
  function = {
    runCommand,
    fetchurl,
    coreutils,
    gcc,
    glibc,
    gawk,
    gnugrep,
    gnumake,
    gnutar,
    gnused,
    gzip,
    zlib,
    binutils,
    buildPlatform,
    runPlatform,
    ...
  }: let
    name = "python";
    version = "3.11.12";

    src = fetchurl {
      url = "https://github.com/python/cpython/archive/refs/tags/v${version}.tar.gz";
      hash = "sha256-tgbaLoO+LuiKE9F5dMHPReCJerwoBXd0MetbYTwMmEo=";
    };

    linker = {
      "x86_64-linux" = "ld-linux-x86-64.so.2";
    }.${runPlatform} or (throw "Unsupported platform: ${runPlatform}");

  in runCommand.onRun {
    inherit name version;
    env = {
      buildCommand = /* bash */ ''
        gzip -d ${src} -c | tar x
        cd cpython-${version}

        # ./configure --help
        ./configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          --without-tests \
          --without-ensurepip \
          CC=${gcc}/bin/gcc\ -I${glibc}/include\ -B${glibc}/lib\ -Wl,--dynamic-linker,${glibc}/lib/${linker},-rpath,${glibc}/lib \
          LDFLAGS=-L${glibc}/lib\ -L${gcc}/lib \
          CFLAGS=-B${glibc}/lib\ -I${glibc}/include

        make -j 4
        make install
      '';
      tools = [
        binutils
        coreutils
        gawk
        gnugrep
        gnumake
        gnutar
        gnused
        gzip
      ];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.stage0) fetchurl;
    inherit (pkgs.self) runCommand bootstrapTools;
    inherit (pkgs.self.bootstrapTools.onBuild) # TODO: add nested elaboration to make this more streamlined
      coreutils
      gcc
      glibc
      gawk
      gnugrep
      gnumake
      gnutar
      gnused
      gzip
      binutils
      zlib
      ;
  };
}
