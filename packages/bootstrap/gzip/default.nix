core:
core.mkPackage {
  function = {
    fetchurl,
    bash_2_05,
    tinycc-mes,
    gnumake,
    gnused-mes,
    gnugrep,
    ...
  }:
  let
    name = "gzip";
    version = "1.2.4";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/gnu/gzip/gzip-${version}.tar.gz";
      sha256 = "0ryr5b00qz3xcdcv03qwjdfji8pasp0007ay3ppmk71wl8c1i90w";
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
      ungz --file ${src} --output gzip.tar
      untar --file gzip.tar
      rm gzip.tar
      cd gzip-${version}

      # Configure
      export CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib -Dstrlwr=unused"
      bash ./configure --prefix=$out

      # Build
      make

      # Install
      mkdir $out
      make install
    '';

  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) tinycc-mes gnumake gnused-mes gnugrep bash_2_05;

    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}
