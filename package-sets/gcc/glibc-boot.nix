{
  function = {
    runCommand,
    fetchurl,
    bash,
    bzip2,
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
    python,
    bison,
    buildPlatform,
    runPlatform,
    ...
  }: let
    name = "glibc";
    version = "2.38";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/glibc/glibc-${version}.tar.bz2";
      hash = "sha256-p2QzJHPd+UMQCb3gSbrIueAhzFwcQSE4qKSoxgD+E7I=";
    };
  in runCommand.onRun {
    inherit name version;
    env = {
      buildCommand = /* bash */ ''
        bzip2 -d ${src} -c | tar x
        cd glibc-${version}
        mkdir build
        cd build

        ../configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          CC=${gcc}/bin/gcc-wrapper

        make -j 4
        make install
      '';
      tools = [
        bash
        bzip2
        binutils
        diffutils
        coreutils
        gawk
        gnugrep
        gnumake
        gnused
        gnutar
        gzip

        python.onBuild
        bison.onBuild
      ];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) runCommand python bison;
    inherit (pkgs.stage0) fetchurl;

    inherit (pkgs.self.bootstrapTools.onBuild) # TODO: add nested elaboration to make this more streamlined for bootstrap
      bash
      bzip2
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
  };
}
