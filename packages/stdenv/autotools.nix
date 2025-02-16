core:
{
  function = {
    mkPhasedBuild, isFunction,
    shell, coreutils, phases,
    buildPlatform, hostPlatform,
    ...
  }: drvInit:
    (mkPhasedBuild (self: let
      init = if isFunction drvInit then drvInit self else drvInit;
    in init // {
      setup = init.setup or {} // {
        phases = {
          inherit (phases) binariesToPath;
        };
        buildOrder = [ "binariesToPath" ];
      };
      drvAttrs = {
        # Autotools specific
        binaries = builtins.attrValues self.setup.binaries or {};
        initialPath = [ coreutils ];

        # required for derivation
        builder = shell;
        system = buildPlatform;
      } // init.drvAttrs or {}; # Allow drvInit to override builder directly
      public = {
        inherit buildPlatform hostPlatform;
      } // init.public or {};
    }));

  dep-defaults = { lib, ... }: let
    # TODO: replace with overrides of shell + bootstrap
    bootstrapFiles = import ./stdenv/linux/bootstrap-files/x86_64-unknown-linux-gnu.nix;
    bootstrapTools = import ./stdenv/linux/bootstrap-tools {
      # HACK: hard-coded values for prototype
      libc = "glibc";
      system = "x86_64-linux";
      inherit bootstrapFiles;
      isFromBootstrapFiles = true;
    };
  in {
    inherit (lib.self.derivation) mkPhasedBuild;
    inherit (lib.self.builder) phases;
    inherit (lib.self.trivial) isFunction;

    shell = "${bootstrapTools}/bin/bash";
    coreutils = bootstrapTools;
  };
}
