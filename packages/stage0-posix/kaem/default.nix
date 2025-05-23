# Ported from Nixpkgs by GrizzlT

core:
core.mkPackage {
  function = {
    std,
    mescc-tools-extra,
    mescc-tools-boot2,
    mkMinimalPackage,
    ...
  }: let

    inherit (std.strings) makeBinPath;
    inherit (mescc-tools-boot2.onHost) kaem-unwrapped;

  in mkMinimalPackage.onHost {
    name = "kaem";
    version = "1.6.0";
    drv = {
      builder = mescc-tools-boot2.onBuild.kaem-unwrapped;
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
    inherit (pkgs.self)
      mescc-tools-boot2
      mescc-tools-extra
      mkMinimalPackage
      ;
  };
}
