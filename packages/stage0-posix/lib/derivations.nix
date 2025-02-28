{ std, ... }:
let
  inherit (std.derivations) encapsulateLayers layers;

  inherit (std.trivial) isFunction;

in {

  mkMinimalPackage = { buildPlatform, hostPlatform, targetPlatform }: attrs: let
    bootstrapPhase = buildPlatform == hostPlatform && hostPlatform == targetPlatform;
  in if bootstrapPhase then encapsulateLayers [
    (layers.package { inherit (attrs) name version; })
    (layers.derivation ({ system = buildPlatform; } // attrs.drv))
    (self: super: {
      public = super.public // (if isFunction (attrs.public or {}) then (attrs.public or {}) super.public else (attrs.public or {}));
    })
  ]
  else null;
}
