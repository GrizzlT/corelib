let
  inherit (import ./consume-prototype.nix) depMapping resolveLibs resolvePkgs;

  stdenv = import ./packages/stdenv;
  sets = { inherit stdenv; };
  map = depMapping sets;
  lib = resolveLibs map sets;
  pkgs = resolvePkgs map lib sets
    { pkgsBuildBuild = pkgs; pkgsBuildHost = pkgs; pkgsBuildTarget = pkgs; pkgsHostHost = pkgs; pkgsHostTarget = pkgs; pkgsTargetTarget = pkgs; }
    { hostPlatform = "x86_64-linux"; buildPlatform = "x86_64-linux"; targetPlatform = "x86_64-linux"; };
in { inherit lib pkgs; }
