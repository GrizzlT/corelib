{
  function = {
    runCommand,
    fetchurl,
    coreutils,
    gnumake,
    binutils,
    gawk,
    gnused,
    # python
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
        ${coreutils.onBuild}/bin/bunzip2 ${src} -c | ${coreutils.onBuild}/bin/tar x
        cd glibc-${version}
        ${coreutils.onBuild}/bin/mkdir build
        cd build

        ../configure --prefix=$out \
          --build=${buildPlatform} \
          --host=${runPlatform} \
          --with-binutils=${binutils.onBuild}/bin \
          CC=${binutils.onBuild}/bin/gcc \
          LDFLAGS=-L${coreutils.onBuild}/lib \
          CLFAGS=-nostdlib
      '';
      tools = [
        # coreutils.onBuild
        # gnumake.onBuild
        # binutils.onBuild
        # gawk.onBuild
        # gnused.onBuild
      ];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) runCommand;
    inherit (pkgs.stage0) fetchurl;

    coreutils = pkgs.self.bootstrapTools;
    gnumake = pkgs.self.bootstrapTools;
    binutils = pkgs.self.bootstrapTools;
    gawk = pkgs.self.bootstrapTools;
    gnused = pkgs.self.bootstrapTools;
  };
}
