let
  consume = import ./consume-prototype.nix;
  mkPackageSet = import ./mk-package-set.nix;
in {
  inherit mkPackageSet;
  inherit (consume) depMapping resolveLibs resolvePkgs bootstrap;
}
