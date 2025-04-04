let
  inherit (import ./consume-prototype.nix) bootstrap;

  # example package set
  stdenv = import ./packages/stage0-posix;

  # TODO: provide convenience function for 1 or 2 platforms
  pkgs = bootstrap (self: {
    final = {
      triple = { buildPlatform = "x86_64-linux"; hostPlatform = "i686-linux"; targetPlatform = "i686-linux"; };
      adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.second; pkgsBuildTarget = self.second; pkgsHostHost = self.final; pkgsHostTarget = self.final; pkgsTargetTarget = self.final; };
    };
    second = {
      triple = { buildPlatform = "x86_64-linux"; hostPlatform = "x86_64-linux"; targetPlatform = "i686-linux"; };
      adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.first; pkgsBuildTarget = self.second; pkgsHostHost = self.first; pkgsHostTarget = self.second; pkgsTargetTarget = self.final; };
    };
    first = {
      triple = { buildPlatform = "x86_64-linux"; hostPlatform = "x86_64-linux"; targetPlatform = "x86_64-linux"; };
      adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.first; pkgsBuildTarget = self.first; pkgsHostHost = self.first; pkgsHostTarget = self.first; pkgsTargetTarget = self.first; };
    };
  }) { inherit stdenv; };

in pkgs
