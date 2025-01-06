let
  mkPackageSet = import ./mk-package-set.nix;
in
  mkPackageSet {
    packages = {
      one = import ./set1/one.nix;
      two = import ./set1/two.nix;
    };
  }
