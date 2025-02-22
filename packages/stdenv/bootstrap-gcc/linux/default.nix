core:
{
  function = { autoCall, ... }: let
    # TODO: add other systems like in nixpkgs
    bootstrapFiles = import ./bootstrap-files/x86_64-unknown-linux-gnu.nix;
    bootstrapTools = import ./bootstrap-tools {
      system = "x86_64-linux";
      inherit bootstrapFiles;
    };

    initBootstrap = init: let
      start = let x = init x; in x;
      withExtraAttrs = raw: let
        addLayer = layer: let
          result = raw // (layer result raw);
        in withExtraAttrs result;
      in raw // { inherit addLayer; };
    in withExtraAttrs start;

    stage1 = initBootstrap (_:
      import ./stage1.nix { inherit bootstrapTools; fetchurl = import ../fetchurl-bootstrap.nix; }
    );

  in stage1;
  dep-defaults = { autoCall, ... }: {
    inherit autoCall;
  };
}
