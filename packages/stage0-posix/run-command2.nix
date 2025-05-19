core:
{
  function = {
    std,
    kaem,
    mescc-tools,
    mescc-tools-extra,
    writeText,
    mkMinimalPackage,
    ...
  }: let
    inherit (std.strings) makeBinPath;
  in {
    name,
    version ? null,
    shell ? "${kaem.onBuild}/bin/kaem",
    env,
    public ? {},
  }: mkMinimalPackage.onHost {
    inherit name version public;

    drv = self: ({
      builder = shell;
      args = env.args or [
        "--verbose"
        "--strict"
        "--file"
        (writeText "${self.package.name}${if self.package.version != "" then "-${self.package.version}" else ""}-builder" env.buildCommand)
      ];
      PATH = makeBinPath (
        (env.tools or [])
        ++ [
          kaem.onBuild
          mescc-tools.onBuild
          mescc-tools-extra.onBuild
        ]
      );
    } // (removeAttrs env [ "tools" "args" "buildCommand" ]));
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
