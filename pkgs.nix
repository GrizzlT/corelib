let
  inherit (import ./consume-prototype.nix) depMapping resolveLibs resolvePkgs;

  set1 = import ./set1.nix;
  sets = { inherit set1; };
  map = depMapping sets;
  lib = resolveLibs map sets;
  pkgs = resolvePkgs map lib sets
    { pkgsBuildBuild = pkgs; pkgsBuildHost = pkgs; pkgsBuildTarget = pkgs; pkgsHostHost = pkgs; pkgsHostTarget = pkgs; pkgsTargetTarget = pkgs; }
    { hostPlatform = "linux"; buildPlatform = "linux"; targetPlatform = "linux"; };
in pkgs
