core:
{
  function = { mkMinimalPackage, hostPlatform, buildPlatform, targetPlatform, ... }:
    mkMinimalPackage { inherit hostPlatform buildPlatform targetPlatform; };

  dep-defaults = { lib, ... }: {
    inherit (lib.self.derivations) mkMinimalPackage;
  };
}
