let
  inherit (import ./lib.nix) bootstrap;

  # example package set
  stage0 = import ./package-sets/stage0-posix;
  bootstrap-pkgs = import ./package-sets/bootstrap;

  bootstrapFn = bootstrap {
    builder = "x86_64-linux";
    runtime = "x86_64-linux";
  };

  pkgs = {
    stage0 = bootstrapFn stage0;
    bootstrap = bootstrapFn bootstrap-pkgs;
  };

in pkgs
