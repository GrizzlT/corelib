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
    name = "m4";
    version = "1.4.20";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/gnu/m4/m4-${version}.tar.gz";
      hash = "sha256-asT8Mc5EDevmOYfC67+de2Y05np8Mnklfcc2Hei9s+8=";
    };

  in runCommand.onRun {
    inherit name version;
    env = {
      buildCommand = /* bash */ ''
        gzip -d ${src} -c | tar x
        cd m4-${version}

        ./configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          CC=${gcc}/bin/gcc-wrapper

        make -j 4
        make install
      '';
      tools = [
        binutils
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
      gcc
      gawk
      gnugrep
      gnumake
      gnutar
      gnused
      gzip
      ;
    inherit (pkgs.self) runCommand;
    inherit (pkgs.stage0) fetchurl;
  };
}

