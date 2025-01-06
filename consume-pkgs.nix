let
  consumePkgs = import ./consume-example.nix;
in
  consumePkgs {
    pkgs1 = import ./set1.nix;
    pkgs2 = import ./set2.nix;
  }
