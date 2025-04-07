core:
core.mkPackage {
  function = {
    fetchurl,
    runCommand,
    ...
  }:
  let
    name = "nyacc";
    # NYACC is a tightly coupled dependency of mes. This version is known to work
    # with mes 0.25.
    # https://git.savannah.gnu.org/cgit/mes.git/tree/INSTALL?h=v0.25#n31
    version = "1.00.2";

    src = fetchurl {
      url = "mirror://savannah/nyacc/nyacc-${version}.tar.gz";
      sha256 = "065ksalfllbdrzl12dz9d9dcxrv97wqxblslngsc6kajvnvlyvpk";
    };

    nyacc = runCommand.onHost "${name}-${version}"
      {
        public.guilePath = "${nyacc}/share/${name}-${version}/module";
      }
      ''
        ungz --file ${src} --output nyacc.tar
        mkdir -p ''${out}/share
        cd ''${out}/share
        untar --file ''${NIX_BUILD_TOP}/nyacc.tar
      '';
  in nyacc;

  dep-defaults = { lib, pkgs, ... }: {
    inherit (lib) std;
    inherit (pkgs.stage0) runCommand;
    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}

