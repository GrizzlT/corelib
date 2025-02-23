core:
{
  function = { autoCall, ... }: let
    # TODO: add other systems like in nixpkgs
    fetchurlBootstrap = import ../fetchurl-bootstrap.nix;

    initBootstrap = init: let
      start = let x = init x; in x;
      withExtraAttrs = raw: let
        addLayer = layer: let
          result = raw // (layer result raw);
        in withExtraAttrs result;
      in raw // { inherit addLayer; };
    in withExtraAttrs start;

    stage0 = initBootstrap (_:
      import ./stage0-posix { fetchurl = fetchurlBootstrap; }
    );

    stage1 = stage0.addLayer (super: self: {
      # tinycc-bootstrappable =
    });

  in stage0;
  dep-defaults = { autoCall, ... }: {
    inherit autoCall;
  };
}
