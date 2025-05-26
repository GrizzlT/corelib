core:
{
  function = { mkMinimalPackage, hostPlatform, buildPlatform, targetPlatform, ... }:
    attrs: mkMinimalPackage {
      inherit hostPlatform buildPlatform targetPlatform;
      onlyOnNative = attrs.onlyOnNative or false;
    } attrs;

  dep-defaults = { lib, ... }: {
    inherit (lib.self.derivations) mkMinimalPackage;
  };
}
