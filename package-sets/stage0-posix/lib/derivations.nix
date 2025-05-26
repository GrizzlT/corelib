{ std, ... }:
let
  inherit (std.derivations) encapsulateLayers layers;

  inherit (std.trivial) isFunction;

in {

  mkMinimalPackage = { buildPlatform, runPlatform, targetPlatform, onlyOnNative }: attrs: let
    bootstrapPhase = buildPlatform == runPlatform && runPlatform == targetPlatform;
  in if (!onlyOnNative || bootstrapPhase) then encapsulateLayers [
    (layers.package {
      inherit (attrs) name version;
    })

    (layers.derivation (self:
      { system = buildPlatform; }
      // (if isFunction attrs.drv then attrs.drv self else attrs.drv)
    ))

    (self: super: {
      public = super.public
        // { inherit buildPlatform runPlatform; }
        // (if isFunction (attrs.public or {}) then (attrs.public or {}) super.public else (attrs.public or {}));
    })
  ]
  else null;
}
