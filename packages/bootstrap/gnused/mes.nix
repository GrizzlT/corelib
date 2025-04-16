core:
core.mkPackage {
  function = {
    fetchurl,
    bash_2_05,
    gnumake,
    tinycc-mes,
    ...
  }:

  let
    name = "gnused-mes";
    # last version that can be compiled with mes-libc
    version = "4.0.9";

    src = fetchurl {
      url = "https://ftpmirror.gnu.org/gnu/sed/sed-${version}.tar.gz";
      sha256 = "0006gk1dw2582xsvgx6y6rzs9zw8b36rhafjwm288zqqji3qfrf3";
    };

    # Thanks to the live-bootstrap project!
    # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/sed-4.0.9.kaem
    makefile = fetchurl {
      url = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/mk/main.mk";
      sha256 = "0w1f5ri0g5zla31m6l6xyzbqwdvandqfnzrsw90dd6ak126w3mya";
    };
  in
  bash_2_05.onHost.runCommand "${name}-${version}"
    {
      tools = [
        gnumake.onBuild
        tinycc-mes.onBuildForHost.compiler
      ];
    }
    ''
      # Unpack
      ungz --file ${src} --output sed.tar
      untar --file sed.tar
      rm sed.tar
      cd sed-${version}

      # Configure
      cp ${makefile} Makefile
      catm config.h

      # Build
      make \
        CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib" \
        LIBC=mes

      # Install
      make install PREFIX=$out
    '';

  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) tinycc-mes gnumake bash_2_05;

    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}
