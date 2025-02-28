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
    inherit (std.attrsets) removeAttrs;
    inherit (mescc-tools-boot.onHostForTarget) kaem-unwrapped;

  in if buildPlatform == hostPlatform && hostPlatform == targetPlatform then mkMinimalPackage.onHost {
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

    # public.runCommand =
    #   # TODO: remove version -> use something other than mkMinimalPackage
    #   name: version: env: buildCommand: mkMinimalPackage {
    #     inherit name version;
    #     drv = {
    #       builder = "${kaem.onBuild}/bin/kaem";
    #       args = [
    #         "--verbose"
    #         "--strict"
    #         "--file"
    #         (writeText "${name}-builder" buildCommand)
    #       ];
    #
    #       PATH = makeBinPath (
    #         (env.tools or [ ])
    #         ++ [
    #           kaem.onBuild
    #           mescc-tools.onBuildForHost
    #           mescc-tools-extra.onBuild
    #         ]
    #       );
    #     } // (removeAttrs env [ "tools" ]);
    #   };
  }
  else null;

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
