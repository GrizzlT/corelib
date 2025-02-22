core:
{
  function = { autoCall, buildPlatform, hostPlatform, targetPlatform, ... }: let
    skipBuild = buildPlatform != hostPlatform || hostPlatform != targetPlatform;

    flavor = if buildPlatform == "x86_64-linux" # target triple is all the same
      then autoCall (import ./linux) {}
      else abort "Unsupported platform for gcc bootstrapping";
  in if skipBuild then null else flavor;

  dep-defaults = { autoCall, ... }: {
    inherit autoCall;
  };
}
