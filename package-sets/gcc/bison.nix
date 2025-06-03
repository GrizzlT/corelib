{
  function = {
    runCommand,
    fetchurl,
    m4,
    binutils,
    coreutils,
    diffutils,
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
    name = "bison";
    version = "3.8.2";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/bison/bison-${version}.tar.gz";
      hash = "sha256-BsnhO99+sk1M62tZIFpPZ8LH5yExGWREMP6C+9FKCrs=";
    };

  in runCommand.onRun {
    inherit name version;
    env = {
      buildCommand = /* bash */ ''
        gzip -d ${src} -c | tar x
        cd bison-${version}

        ./configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          CC=${gcc}/bin/gcc-wrapper

        make -j 4
        make install
      '';
      tools = [
        binutils
        diffutils
        m4.onBuild
        coreutils
        gawk
        gnugrep
        gnumake
        gnused
        gnutar
        gzip
      ];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self.bootstrapTools.onBuild) # TODO: add nested elaboration to make this more streamlined for bootstrap
      binutils
      coreutils
      diffutils
      gcc
      gawk
      gnugrep
      gnumake
      gnutar
      gnused
      gzip
      ;
    inherit (pkgs.self) runCommand m4;
    inherit (pkgs.stage0) fetchurl;
  };
}

