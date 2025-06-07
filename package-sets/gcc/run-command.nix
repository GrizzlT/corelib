lib:
{
  function = {
    bash,
    writeText,
    mkMinimalPackage,
    ...
  }: let
    inherit (lib.std.strings) makeBinPath;
  in {
    name,
    version ? null,
    shell ? "${bash.onBuild}/bin/bash",
    env,
    public ? {},
  }: mkMinimalPackage.onRun {
    inherit name version public;

    drv = self: ({
      builder = shell;
      args = env.args or [
        "--verbose"
        (writeText "${self.package.name}${if (self.package.version != null && self.package.version != "") then "-${self.package.version}" else ""}-builder" env.buildCommand)
      ];
      PATH = makeBinPath (
        (env.tools or [])
      );
    } // (removeAttrs env [ "tools" "args" "buildCommand" ]));
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self)
      bash
      writeText
      ;
    inherit (pkgs.stage0)
      mkMinimalPackage
      ;
  };
}
