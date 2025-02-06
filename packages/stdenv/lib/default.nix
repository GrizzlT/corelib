lib:

{
  trivial = { inherit (import ./trivial.nix lib) isFunction; };
  inherit (lib.self.trivial) isFunction;

  fixedPoints = { inherit (import ./fixed-points.nix lib) fix extends composeExtensions; };
  inherit (lib.self.fixedPoints) fix extends composeExtensions;

  attrsets = { inherit (import ./attrsets.nix lib) genAttrs; };
  inherit (lib.self.attrsets) genAttrs;

  inherit (import ../stdenv/generic/make-derivation.nix lib) mkDrv mkPackage mkDerivationFromStdenv;
}
