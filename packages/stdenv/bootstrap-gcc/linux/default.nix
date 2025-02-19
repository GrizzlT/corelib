core:
{
  function = { autoCall, ... }: let
    # TODO: add other systems like in nixpkgs
    bootstrapFiles = import ./bootstrap-files/x86_64-unknown-linux-gnu.nix;

    /*
      Other derivations could be constructed internally
    */
    bootstrapTools = import ./bootstrap-tools {
      # HACK: hard-coded values for prototype
      system = "x86_64-linux";
      inherit bootstrapFiles;
    };
  in bootstrapTools;
  dep-defaults = { autoCall, ... }: {
    inherit autoCall;
  };
}
