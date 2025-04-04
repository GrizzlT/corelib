# Ported from Nixpkgs by GrizzlT

core:
core.mkPackage {
  function = {
    std,
    platforms,
    mescc-tools,
    mescc-tools-extra,
    mescc-tools-boot,
    kaem,
    writeText,
    mkMinimalPackage,
    buildPlatform,
    hostPlatform,
    targetPlatform,
    ...
  }: let

    inherit (std.strings) makeBinPath;
    inherit (mescc-tools-boot.onHostForTarget) kaem-unwrapped;

  in mkMinimalPackage {
    name = "kaem";
    version = kaem-unwrapped.version;
    drv = {
      builder = kaem-unwrapped;
      args = [
        "--verbose"
        "--strict"
        "--file"
        (builtins.toFile "kaem-wrapper.kaem" ''
          mkdir -p ''${out}/bin
          cp ''${kaem-unwrapped} ''${out}/bin/kaem
          chmod 555 ''${out}/bin/kaem
        '')
      ];
      PATH = makeBinPath [ mescc-tools-extra.onBuild ];
      inherit
        kaem-unwrapped
        ;
    };
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (lib.self) platforms;
    inherit (pkgs.self)
      kaem
      mescc-tools
      mescc-tools-boot
      mescc-tools-extra
      mkMinimalPackage
      writeText
      ;
  };
}
