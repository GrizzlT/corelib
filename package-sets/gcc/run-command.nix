{ std, self, ... }:
{
  function = {
    bash,
    buildPlatform,
    runPlatform,
    ...
  }: let
    inherit (std.attrsets) optionalAttrs;
    inherit (self.derivations) composeBuild layers mergeFixpointAttr;

    getOptionalAttrs = names: attrs:
      builtins.foldl' (acc: name: acc // (optionalAttrs (attrs ? ${name}) {
        ${name} = attrs.${name};
      })) {} names;
  in
    attrs': composeBuild [
      layers.package
      layers.derivation
      (layers.setPathEnv [ "tools" ])
      (layers.runShellScript {
        shell = "${bash.onBuild}/bin/bash";
        inherit buildPlatform;
      })

      # tying it all together
      ({ env ? {}, ... }@attrs: self: super: {
        scriptAttrs = getOptionalAttrs ["buildScript" "shell" "args"] attrs;
        drvAttrs = super.drvAttrs // (mergeFixpointAttr env self super);
        public = super.public or {}
          // { inherit buildPlatform runPlatform; };
      })

    ] attrs';

  inputs = { pkgs, ... }: {
    inherit (pkgs.self)
      bash
      ;
  };
}
