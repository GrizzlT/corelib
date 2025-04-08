let
  inherit (import ./consume-prototype.nix) bootstrap;

  # example package set
  stdenv = import ./packages/bootstrap;

  # TODO: provide convenience function for 1 or 2 platforms
  pkgs = bootstrap (self: let
    buildSystem = "i686-linux";
    runSystem = "riscv64-linux";
  in {
    final = {
      triple = { buildPlatform = buildSystem; hostPlatform = buildSystem; targetPlatform = buildSystem; };
      adjacent = { pkgsBuildBuild = self.final; pkgsBuildHost = self.final; pkgsBuildTarget = self.final; pkgsHostHost = self.final; pkgsHostTarget = self.final; pkgsTargetTarget = self.final; };
    };
    # final = {
    #   triple = { buildPlatform = buildSystem; hostPlatform = runSystem; targetPlatform = runSystem; };
    #   adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.second; pkgsBuildTarget = self.second; pkgsHostHost = self.final; pkgsHostTarget = self.final; pkgsTargetTarget = self.final; };
    # };
    # second = {
    #   triple = { buildPlatform = buildSystem; hostPlatform = buildSystem; targetPlatform = runSystem; };
    #   adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.first; pkgsBuildTarget = self.second; pkgsHostHost = self.first; pkgsHostTarget = self.second; pkgsTargetTarget = self.final; };
    # };
    # first = {
    #   triple = { buildPlatform = buildSystem; hostPlatform = buildSystem; targetPlatform = buildSystem; };
    #   adjacent = { pkgsBuildBuild = self.first; pkgsBuildHost = self.first; pkgsBuildTarget = self.first; pkgsHostHost = self.first; pkgsHostTarget = self.first; pkgsTargetTarget = self.first; };
    # };
  }) { inherit stdenv; };

in pkgs
