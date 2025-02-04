core:
{
  function = { autoCall, mkStdenv, ... }: let
    # TODO: add other systems like in nixpkgs
    bootstrapFiles = import ./bootstrap-files/x86_64-unknown-linux-gnu.nix;

    bootstrapTools = import ./bootstrap-tools {
      # TODO: hard-coded values for prototype
      libc = "glibc";
      system = "x86_64-linux";
      inherit bootstrapFiles;
      isFromBootstrapFiles = true;
    };
  in mkStdenv.onBuild {
    shell = "${bootstrapTools}/bin/bash";
    initialPath = [bootstrapTools];
    fetchurlBoot = import ../fetchurl-bootstrap.nix;
    cc = null;
  };
  dep-defaults = { autoCall, pkgs, ... }: {
    inherit (pkgs.self) mkStdenv;
    inherit autoCall;
  };
}
