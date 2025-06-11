lib:
{
  function = {
    bash,
    buildPlatform,
    runPlatform,
    ...
  }: let
    inherit (lib.std.attrsets) optionalAttrs;
    inherit (lib.self.derivations) composeBuild layers;
  in
    attrs': composeBuild [
      layers.package
      layers.derivation
      (layers.setPathEnv [ "tools" ])
      (attrs: self: super: {
        drvAttrs = super.drvAttrs or {} // {
          system = buildPlatform;
          builder = attrs.shell or "${bash.onBuild}/bin/bash";
          args = attrs.args or [
            (builtins.toFile "call-build-command.sh" ''
              source "''${buildCommandPath}"
            '')
          ];
        }
          // (optionalAttrs (attrs ? buildCommand) {
            inherit (attrs) buildCommand;
            passAsFile = attrs.env.passAsFile or [] ++ ["buildCommand"];
          })
          // (removeAttrs attrs.env or {} ["passAsFile"]);
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
