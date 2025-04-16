core:
core.mkPackage {
  function = {
      fetchurl,
      bash_2_05,
      tinycc-mes,
      gnumake,
      ...
    }:
    let
      name = "gnugrep";
      version = "2.4";

      src = fetchurl {
        url = "https://ftpmirror.gnu.org/gnu/grep/grep-${version}.tar.gz";
        sha256 = "05iayw5sfclc476vpviz67hdy03na0pz2kb5csa50232nfx34853";
      };

      # Thanks to the live-bootstrap project!
      # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/grep-2.4
      makefile = fetchurl {
        url = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/grep-2.4/mk/main.mk";
        sha256 = "08an9ljlqry3p15w28hahm6swnd3jxizsd2188przvvsj093j91k";
      };
    in
    bash_2_05.onHost.runCommand "${name}-${version}"
      {
        tools = [
          tinycc-mes.onBuildForHost.compiler
          gnumake.onBuild
        ];
      }
      ''
        # Unpack
        ungz --file ${src} --output grep.tar
        untar --file grep.tar
        rm grep.tar
        cd grep-${version}

        # Configure
        cp ${makefile} Makefile

        # Build
        make CC="tcc -B ${tinycc-mes.onBuildForHost.libs}/lib"

        # Install
        make install PREFIX=$out
      '';

  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) tinycc-mes gnumake bash_2_05;

    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}

