let

  inherit (import ./generate-elaborate.nix) generateBootstrapFunction;

  pushDownPlatforms = attrs: let
    packages = foldlAttrs
      (acc: _: value: acc // (builtins.mapAttrs (_: _: 0) value))
      {}
      attrs;
  in builtins.mapAttrs
    (name: _: foldlAttrs
      (acc: flavor: value: acc // (if value ? ${name} then { ${flavor} = value.${name}; } else {}))
      {}
      attrs
    )
    packages;

  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  isFunction = f: builtins.isFunction f ||
    (f ? __functor && isFunction (f.__functor f));

  /*
    Given a cross-compile bootstrap function or strategy, this function
    computes the required fixpoint to elaborate and collect all the package
    recipe results in the given package set.

    This function makes sure the necessary cross-compile context is correctly
    provided for each package elaboration.

    The advantages of this approach are the tree-structure between dependency
    package sets, the flexibility of a canadian cross, the convenience of a
    single-platform build, the explicit choice of build-native or run-native
    binaries and the interoperability with input frameworks such as Atoms.

    # Input
    `pkgSet`:
          The package set that is to be elaborated. This is an attribute set
          that has attributes `lib`, `packages` and `dependencies`. `lib`
          contains pure functions and global input values. It may be
          constructed as a fixpoint of itself. This `lib` is directly passed to
          each package. `dependencies` is an attribute set of other package
          sets just like this parameter. `packages` is an attribute set of a
          package or recipe. It is evaluated in a cross-compiled context, see
          below.

    `bootstrapFn`:
          The cross-compile strategy or setting. This is the result of the
          `generateBootstrapFunction` function.

    # Type
    elaboratePkgs :: Attrset -> (Attrset -> Attrset) -> Attrset

   */
  elaboratePkgs = pkgSet: bootstrapFn:
    let
      elaboratedDeps = builtins.mapAttrs (_: value: elaboratePkgs value bootstrapFn) pkgSet.dependencies or {};

      buildFromTriple = triples: pkgName: run: target: let
        elaborateRecursive = pkgs: name: let
          pkg = pkgs.${pkgName} or null;
          elaborateRule = pkg.__elaborate or true;

          elaborated = if pkg.targetPlatform or null == null then {
            ${"on" + run} = pkg;
          } else {
            ${"on" + run + "For" + target} = pkg;
          };
        in (if pkg == null then {} else (
          if elaborateRule != false then elaborated else pkg
        ) // { __elaborate = elaborateRule; });
      in elaborateRecursive triples.${"pkgs" + run + target} pkgName;

      splicePkgs = triples: pkgNames: let
        spliced = builtins.foldl' (acc: pkg: let
          splicer = buildFromTriple triples pkg;
          splicedPkg = (splicer "Build" "Build") //
            (splicer "Build" "Target") //
            (splicer "Build" "Run") //
            (splicer "Target" "Target") //
            (splicer "Run" "Run") //
            (splicer "Run" "Target");
          slimmedPkg = builtins.removeAttrs splicedPkg [ "__elaborate" ];
        in acc // { ${pkg} = slimmedPkg // (
          if splicedPkg.__elaborate == "recursive" then
            { __elaborate = pushDownPlatforms slimmedPkg; }
          else {}
        ); }) {} pkgNames;
      in spliced;

      /*
        Returns the spliced set of 6 different platform triples required to build
        the original bootstrap specification.
       */
      crossResolver =
        { pkgsBuildBuild, pkgsBuildRun, pkgsBuildTarget, pkgsRunRun, pkgsRunTarget, pkgsTargetTarget }@triples:
        { buildPlatform, runPlatform, targetPlatform }@platforms:
        perspective:
      let
        pkgsDep = builtins.mapAttrs (name: value: let
          inherit ((bootstrapFn elaboratedDeps.${name}).${perspective}) adjacent;
        in splicePkgs adjacent (builtins.attrNames value.packages or {})) pkgSet.dependencies or {};

        pkgsSelf = pkgsDep // { self = splicePkgs triples (builtins.attrNames (pkgSet.packages or {})); };

        /*
          Elaborate a single package in the current cross-compile context.
          This function is given to each package to allow for recursive elaboration.
         */
        deferCall = pkg: overrides: let
          lib' = if isFunction pkgSet.lib then pkgSet.lib lib' else pkgSet.lib;
          pkg' = if isFunction pkg then pkg lib' else pkg;
          deps = pkg'.inputs or (_: {}) ({
            pkgs = pkgsSelf;
            inherit deferCall;
          } // platforms);
        in pkg'.function (deps // platforms);
      in builtins.mapAttrs (name: pkg: deferCall pkg {}) (pkgSet.packages or {});

      stages = builtins.mapAttrs (name: value: crossResolver value.adjacent value.triple name) (bootstrapFn stages);
    in stages;

in {
  inherit elaboratePkgs generateBootstrapFunction;
}
