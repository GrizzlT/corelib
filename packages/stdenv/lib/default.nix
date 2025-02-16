lib:

{
  trivial = import ./trivial.nix lib;
  inherit (lib.self.trivial) isFunction;

  fixedPoints = import ./fixed-points.nix lib;
  inherit (lib.self.fixedPoints) fix extends composeExtensions;

  attrsets = import ./attrsets.nix lib;
  inherit (lib.self.attrsets) genAttrs;

  strings = import ./strings.nix lib;

  inherit (import ./derivation.nix lib) mkDrv mkPackage;
}
