# Ported from Nixpkgs by GrizzlT

# Does not produce code (targetPlatform == null)

lib:
{
  function = {
    mescc-tools,
    mescc-tools-boot2,
    m2libc,
    src,
    mkMinimalPackage,
    buildPlatform,
    runPlatform,
    targetPlatform,
    ...
  }: let

    inherit (mescc-tools-boot2.onBuild) kaem-unwrapped;

    m2libcArch = lib.self.platforms.m2libcArch runPlatform;
    m2libcOS = "Linux"; # NOTE: hardcoded to linux!

  in mkMinimalPackage.onRun {
    name = "mescc-tools-extra";
    version = "1.8.0";
    drv = {
      builder = kaem-unwrapped;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./build.kaem
      ];
      mescc-tools = mescc-tools.onBuild;
      mkdir = mescc-tools.onBuild.mkdir;
      inherit
        src
        m2libcArch
        m2libcOS
        ;
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) mkMinimalPackage mescc-tools-boot2 mescc-tools;

    src = pkgs.self.minimal-bootstrap-sources;
    m2libc = pkgs.self.minimal-bootstrap-sources.m2libc;
  };
}
