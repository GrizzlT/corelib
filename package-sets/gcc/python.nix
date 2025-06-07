lib:
{
  function = {
    runCommand,
    fetchurl,
    binutils,
    coreutils,
    gcc,
    gawk,
    gnugrep,
    gnumake,
    gnutar,
    gnused,
    gzip,
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
          CC=${gcc.onBuild}/bin/gcc-wrapper

        make -j 4
        make install
      '';
      tools = [
        binutils.onBuild
        coreutils.onBuild
        gawk.onBuild
        gnugrep.onBuild
        gnumake.onBuild
        gnutar.onBuild
        gnused.onBuild
        gzip.onBuild
      ];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.stage0) fetchurl;
    inherit (pkgs.self) runCommand;
    inherit (lib.self.pushDownPlatforms pkgs.self.bootstrapTools)
      binutils
      coreutils
      gcc
      gawk
      gnugrep
      gnumake
      gnutar
      gnused
      gzip
      ;
  };
}
