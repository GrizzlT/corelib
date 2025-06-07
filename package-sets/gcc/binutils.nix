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
    name = "binutils";
    version = "2.44";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/binutils/binutils-${version}.tar.gz";
      hash = "sha256-DN12d3oN/T3Tpj8hXwMCCN25HCNh0rzAKs7A8cFrai4=";
    };

  in runCommand.onRun {
    inherit name version;
    env = {
      buildCommand = /* bash */ ''
        set -eu
        gzip -d ${src} -c | tar x
        cd binutils-${version}

        ./configure --help
        ./configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          --disable-gprofng \
          --disable-gold \
          --disable-libquadmath \
          --disable-libstdcxx \
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

