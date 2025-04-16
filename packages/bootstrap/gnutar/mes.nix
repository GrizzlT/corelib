core:
core.mkPackage {
  function = {
    fetchurl,
    bash_2_05,
    tinycc-mes,
    gnumake,
    gnused-mes,
    gnugrep,
    buildPlatform,
    hostPlatform,
    ...
  }:
  let
    name = "gnutar";
    # >= 1.13 is incompatible with mes-libc
    version = "1.12";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/gnu/tar/tar-${version}.tar.gz";
      sha256 = "02m6gajm647n8l9a5bnld6fnbgdpyi4i3i83p7xcwv0kif47xhy6";
    };
  in
  bash_2_05.onHost.runCommand "${name}-${version}"
    {
      tools = [
        tinycc-mes.onBuildForHost.compiler
        gnumake.onBuild
        gnused-mes.onBuild
        gnugrep.onBuild
      ];
    }
    ''
      # Unpack
      ungz --file ${src} --output tar.tar
      untar --file tar.tar
      rm tar.tar
      cd tar-${version}

      # Configure
      export CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib"
      bash ./configure \
        --build=${buildPlatform} \
        --host=${hostPlatform} \
        --disable-nls \
        --prefix=$out

      # Build
      make AR="tcc -ar"

      # Install
      make install
    '';

  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) tinycc-mes gnumake gnused-mes gnugrep bash_2_05;

    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}

