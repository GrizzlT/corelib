{
  function = { deferCall, runPlatform, ... }: let

    files = {
      # "i686-linux" = import ./i686-unknown-linux-gnu.nix fetchurl;
      "x86_64-linux" = deferCall (import ./x86_64-unknown-linux-gnu.nix) {};
    }.${runPlatform} or (throw "Unsupported system: ${runPlatform}");

  in files;

  inputs = { pkgs, deferCall, ... }: {
    inherit deferCall;
  };
}
