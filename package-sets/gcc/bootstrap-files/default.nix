{
  function = { fetchurl, runCommand, runPlatform, ... }: let

    files = {
      # "i686-linux" = import ./i686-unknown-linux-gnu.nix fetchurl;
      "x86_64-linux" = import ./x86_64-unknown-linux-gnu.nix fetchurl;
    }.${runPlatform} or (throw "Unsupported system: ${runPlatform}");

  in runCommand.onRun {
    name = "bootstrap-files-${runPlatform}";
    version = null;
    env = {
      buildCommand = /* sh */ ''
        unxz --file ${files} --output src.tar
        mkdir -p ''${out}
        cd ''${out}
        untar --file ''${NIX_BUILD_TOP}/src.tar

        chmod 555 ''${out}/lib/ld-linux-x86-64.so.2
      '';
      allowedReferences = [];
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.stage0) fetchurl runCommand;
  };
}
