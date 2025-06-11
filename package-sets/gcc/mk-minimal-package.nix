lib:
{
  function = { buildPlatform, runPlatform, targetPlatform, ... }:
  let
    inherit (lib.self.derivations) composeBuild layers;
    inherit (lib.std.trivial) isFunction;

    bootstrapPhase = buildPlatform == runPlatform && runPlatform == targetPlatform;
  in
    attrs: if (!attrs.onlyOnNative or false || bootstrapPhase) then
      composeBuild [
        layers.package
        layers.derivation
        (topAttrs: self: super: {
          drvAttrs = super.drvAttrs or {} // {
            system = buildPlatform;
          } // (if isFunction topAttrs.drv then topAttrs.drv self else topAttrs.drv);
          public = super.public or {}
            // { inherit buildPlatform runPlatform; };
        })
      ] attrs else null;
}
