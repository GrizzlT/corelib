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
    # with mes 0.27.
    version = "1.00.2";

    src = fetchurl {
      url = "https://mirror.easyname.at/nongnu/nyacc/nyacc-${version}.tar.gz";
      sha256 = "sha256-825Pt91STcP0s1TT1TE/aefOWmrpNxHoz21R6qjSsxg=";
    };

    nyacc = runCommand.onHost {
      inherit name version;
      public.guilePath = "${nyacc}/share/${name}-${version}/module";
      env.buildCommand = ''
        ungz --file ${src} --output nyacc.tar
        mkdir -p ''${out}/share
        cd ''${out}/share
        untar --file ''${NIX_BUILD_TOP}/nyacc.tar
      '';
    };
  in nyacc;

  dep-defaults = { lib, pkgs, ... }: {
    inherit (lib) std;
    inherit (pkgs.stage0) fetchurl runCommand;
  };
}

