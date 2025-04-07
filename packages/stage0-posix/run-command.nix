core:
core.mkPackage {
  function = {
    std,
    kaem,
    mescc-tools,
    mescc-tools-extra,
    writeText,
    mkMinimalPackage,
    targetPlatform,
    ...
  }: let
    inherit (std.attrsets) removeAttrs optionalAttrs;
    inherit (std.strings) makeBinPath;
  in {
    __functor = _: name: env: buildCommand: mkMinimalPackage.onHost {
      inherit name;
      version = "";
      drv = self: ({
        builder = "${kaem.onBuild}/bin/kaem";
        args = [
          "--verbose"
          "--strict"
          "--file"
          (writeText "${self.public.name}-builder" buildCommand)
        ];
        PATH = makeBinPath (
          (env.tools or [])
          ++ [
            kaem.onBuild
            mescc-tools.onBuild
            mescc-tools-extra.onBuild
          ]
        );
      } // (removeAttrs env [ "tools" "public" ]));
      public = env.public or {};
    };
    inherit targetPlatform;
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (pkgs.self)
      kaem
      mescc-tools
      mescc-tools-extra
      mkMinimalPackage
      writeText
      ;
  };
}
