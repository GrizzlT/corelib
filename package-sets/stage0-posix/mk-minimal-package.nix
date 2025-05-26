lib:
{
  function = { buildPlatform, runPlatform, targetPlatform, ... }:
    attrs: lib.self.derivations.mkMinimalPackage {
      inherit buildPlatform runPlatform targetPlatform;
      onlyOnNative = attrs.onlyOnNative or false;
    } attrs;
}
