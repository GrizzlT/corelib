core:
{
  function = { four, ... }: {
    value = "three " + four.onBuild.value;
  };
  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) four;
  };
}
