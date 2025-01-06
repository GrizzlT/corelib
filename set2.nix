let
  mkPackageSet = import ./mk-package-set.nix;
in
  mkPackageSet {
    packages = {
      one = import ./set2/four.nix;
      two = import ./set2/three.nix;
    };
    dependencies = {
      pkgs1 = import ./set1.nix;
    };
  }
