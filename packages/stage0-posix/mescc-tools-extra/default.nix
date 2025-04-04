# Ported from Nixpkgs by GrizzlT

# Does not produce code (targetPlatform == null)

core:
core.mkPackage {
  function = {
    platforms,
    mescc-tools,
    mescc-tools-boot2,
    m2libc,
    src,
    mkMinimalPackage,
    buildPlatform,
    hostPlatform,
    targetPlatform,
    ...
  }: let

    inherit (mescc-tools-boot2.onBuildForHost) kaem-unwrapped;

    m2libcArch = platforms.m2libcArch hostPlatform;
    m2libcOS = "linux"; # NOTE: hardcoded to linux!

  in mkMinimalPackage.onHost {
    name = "mescc-tools-extra";
    version = "1.6.0";
    drv = {
      builder = kaem-unwrapped;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./build.kaem
      ];
      mescc-tools = mescc-tools.onBuildForHost;
      inherit
        src
        m2libcArch
        m2libcOS
        ;
    };
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib.self) platforms;
    inherit (pkgs.self) mkMinimalPackage mescc-tools-boot2 mescc-tools;
    src = pkgs.self.minimal-bootstrap-sources.onHost;
    m2libc = pkgs.self.minimal-bootstrap-sources.onHost.m2libc;
  };
}
