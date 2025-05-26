# Ported from Nixpkgs by GrizzlT

lib:
{
  function = {
    mescc-tools-extra,
    mescc-tools-boot2,
    mkMinimalPackage,
    ...
  }: let

    inherit (lib.std.strings) makeBinPath;
    inherit (mescc-tools-boot2.onRun) kaem-unwrapped;

  in mkMinimalPackage.onRun {
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

  inputs = { pkgs, ... }: {
    inherit (pkgs.self)
      mescc-tools-boot2
      mescc-tools-extra
      mkMinimalPackage
      ;
  };
}
