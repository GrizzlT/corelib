let
  inherit (import ./consume-prototype.nix) bootstrap;

  # example package set
  stdenv = import ./packages/stdenv;

  # TODO: provide convenience function for 1 or 2 platforms
  pkgs = bootstrap (self: {
    final = {
      triple = { buildPlatform = "x86_64-linux"; hostPlatform = "x86_64-linux"; targetPlatform = "x86_64-linux"; };
      adjacent = { pkgsBuildBuild = self.final; pkgsBuildHost = self.final; pkgsBuildTarget = self.final; pkgsHostHost = self.final; pkgsHostTarget = self.final; pkgsTargetTarget = self.final; };
    };
  }) { inherit stdenv; };

in pkgs
