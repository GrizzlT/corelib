let
  inherit (import ./elaborate.nix) generateBootstrapFunction elaboratePkgs;

  bootstrap =
    { builder, runtime, gcc-target ? runtime }:
    pkgSet: let
      elaborated = elaboratePkgs pkgSet (generateBootstrapFunction {
        buildPlatform = builder;
        runPlatform = runtime;
        targetPlatform = gcc-target;
      });
    in elaborated.pkgsRunTarget;

in {
  inherit bootstrap;
}
