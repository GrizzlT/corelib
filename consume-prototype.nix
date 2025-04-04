let
  inherit (import ./util.nix) foldlAttrs isFunction core;

  /*
    ## Creates a mapping dictionary for the given package sets.

    Each package set has dependencies. To allow for a simple implementation to
    construct cross-compiled packages, all dependency sets are flattened into
    one attribute set. To make sure there are no name collisions for these sets,
    mappings are provided that guarantee uniqueness.

    The result of this function is an attribute set with a `root`
    attribute. This `root` contains mappings for the given package sets of the
    input. Each mapped name is also included in the result set with mappings for
    its dependencies respectively.

    ### Example:

    Input:
    ```nix
    {
      set1 = {
        dependencies = {
          dep1 = {
            # ...
          }
        }
      }
    }
    ```

    Output:
    ```nix
    {
      root = {
        set1 = "mapped_set1";
      };
      mapped_set1 = {
        dep1 = "mapped_dep1";
      };
      mapped_dep1 = {
        # ...
      };
    }
    ```

    The current implementation guarantees a unique mapping by simply appending a
    strictly increasing counter to each name.
  */
  depMapping = pkgSets: let
    recurseDep = meta: dep: foldlAttrs (acc: name: value: let
      depName = name + "_${toString acc.counter}";
      depValue = recurseDep { counter = acc.counter + 1; } value;
    in acc // {
      counter = depValue.counter;
      mappings = acc.mappings or {} // { ${name} = depName; };
      other = acc.other or {} // depValue.other or {} // { ${depName} = depValue.mappings or {}; };
    }) { inherit (meta) counter; } dep.dependencies;

    root = let
      resolved = recurseDep { counter = 1; } { dependencies = pkgSets; };
    in { root = resolved.mappings or {}; } // resolved.other;
  in root;

  /*
    ## Resolves pure functions for the given package sets.

    Each package set can export pure functions under its `lib` attribute. With a
    given mapping (see [`depMapping`]), these pure functions are recursively
    resolved and flattened into an attribute set mapped by the keys of the
    given mapping.

    Each `lib` attribute must be a function that takes in an attribute set. This
    attribute set contains the resolved value of the `lib` function from each of
    the set's dependencies, keyed by the names of the dependencies as listed in
    the package set itself. A special key `self` is reserved for the result of
    the package set's `lib` function. This construction introduces a fixpoint
    per package set.

    Note that this computes a fixpoint per package set.
  */
  resolveLibs = depMappings: pkgSets: let
    /*
      Resolves one lib in the context of `mapping`, `result` is assumed to
      contain the required dependencies listed in `mapping`. `mapping` is
      contextualized to the specific `dep` (i.e. package set) that is being
      resolved.

      This computes a fixpoint.
    */
    resolveDep = result: mappings: dep: let
      lib = foldlAttrs (acc: name: value: acc // { ${name} = result.${value}; }) {} mappings;
      resolved = dep.lib (lib // { self = resolved; });
    in resolved;

    /*
      Resolves the package set `dep` by recursively resolving its dependencies
      after which the set itself can be resolved with [`resolveDep`].

      `name` is the mapped name of the package set being resolved.
    */
    recurseDep = result: name: dep: let
      depRes = recurseIntoDeps result name dep.dependencies;
    in depRes // {
      ${name} = resolveDep depRes depMappings.${name} dep;
    };

    /*
      Resolves each package set in `deps`. `parent` is the mapped name of the
      package set depending on `deps`.
    */
    recurseIntoDeps = result: parent: deps:
      foldlAttrs (acc: name: value: recurseDep acc depMappings.${parent}.${name} value) result deps;

  /*
    The top-level resolution calls [`recurseIntoDeps`] to get a flattened list of
    the complete dependency tree for each package set. It then resolves all
    package sets by calling [`resolveDep`].
  */
  in foldlAttrs (acc: name: value: let
      setName = depMappings.root.${name};
      children = recurseIntoDeps acc setName value.dependencies;
      resolved = resolveDep children depMappings.${setName} value;
    in children // { ${depMappings.root.${name}} = resolved; }) {} pkgSets;

  /*
    ## Resolves platform-dependent functions for the given package sets.

    Each package set can export platform-dependent expressions under its
    `packages` attribute. With a given mapping, result from [`resolveLibs`] and
    adjacent cross-compiled package sets, these expressions are recursively
    resolved and flattened into an attribute set mapped by the keys of the given
    mapping.

    TODO: refer to `core` functions

    Each attribute under `packages` can be either a function or an attribute
    set, but must result into an attribute set with a `function` and
    `dep-defaults` key, both with a function assigned.

    The `dep-defaults` function receives an attribute set as parameter
    containing the resolved values of the `packages` attributes from each of the
    set's dependencies, keyed by the names of the dependencies as listed in the
    package set itself. It must return the default arguments that should be
    passed on to the `function` attribute. Each package will be resolved by
    computing these default dependencies and passing them to `function` with the
    platform triple (buildPlatform, hostPlatform, targetPlatform) appended to
    it.

    The resolved values of each package will be presented as an explicitly
    spliced set of expressions. This will consist between 3 and 6 attributes in
    the form of `on*For*` corresponding to the 6 input attributes
    `pkgsBuildBuild` etc. If `targetPlatform` is missing or set to `null` in a
    package, this form changes to `on*`.

    These resolved values will be listed under a `pkgs` key. a `lib` key will be
    available with the same contents as for the [`resolveLibs`] function. The
    platform triple will also be present. A special key `self` is reserved for
    the spliced result of the package set's packages. This construction
    introduces a fixpoint per package set.

    Note that this computes a fixpoint per package set.
  */
  resolvePkgs = depMappings: lib: pkgSets:
    { pkgsBuildBuild, pkgsBuildHost, pkgsBuildTarget, pkgsHostHost, pkgsHostTarget, pkgsTargetTarget }@triples:
    { hostPlatform, buildPlatform, targetPlatform }@platform: # Add custom args here
  let
    /*
      Given the host and target platform (build/host/target) and the mapping of
      a given package set, a Constructs the key for this host and target for a
      given package. If the package does not export `targetPlatform` or it is
      `null`, this will be of the form `on*`, otherwise it is of the form
      `on*For*`.

      If the package is not in the corresponding `pkgsHostTarget` set, an empty
      attribute set is returned.
    */
    # NOTE: filter out nulls is possible
    buildFromTriple = depName: pkgName: host: target: let
      triple = triples.${"pkgs" + host + target};
    in if triple.${depName} ? ${pkgName} then let pkg = triple.${depName}.${pkgName}; in
      if pkg.targetPlatform or null == null then { ${"on" + host} = pkg; noSplice = pkg.noSplice or false; }
      else { ${"on" + host + "For" + target} = pkg; noSplice = pkg.noSplice or false; }
    else {};

    /*
      Returns the explicitly spliced version of a package.
      See https://github.com/NixOS/nixpkgs/issues/227327 for the maximum amount
      of attributes possible.

      Special packages that declare the `noSplice` attribute are not spliced.
    */
    spliceDep = depName: pkgNames: let
      spliced = builtins.foldl' (acc: pkg: let
        splicer = buildFromTriple depName pkg;
      in acc // { ${pkg} =
        (splicer "Build" "Build") //
        (splicer "Build" "Target") //
        (splicer "Build" "Host") //
        (splicer "Target" "Target") //
        (splicer "Host" "Host") //
        (splicer "Host" "Target");
      }) {} pkgNames;
    in if spliced.noSplice or false then spliced.onBuildForHost or spliced.onBuild else spliced;

    /*
      Resolves one package set in the context of `mapping` which is
      contextualized to the specific `dep` (i.e. package set). This happens as
      is described earlier.

      A convenience attribute `autoCall` is passed on to the packages to allow
      packages to resolve packages internally within the same context but
      without needing to go through the fixpoint and without exposing the inner
      package to the outside world. This takes two arguments: the package
      definition described earlier and an attribute set of input overrides.

      This computes a fixpoint.
    */
    resolveDep = mappings: depName: dep: let
      lib' = (foldlAttrs (acc: name: value: acc // { ${name} = lib.${value}; }) {} mappings) // { self = lib.${depName}; };
      pkgs = foldlAttrs (acc: name: value: acc // { ${name} = spliceDep mappings.${name} (builtins.attrNames value.packages); }) {} dep.dependencies;
      pkgsSelf = pkgs // { self = spliceDep depName (builtins.attrNames dep.packages); };

      # TODO: expand platforms with same stuff in nixpkgs
      autoCall = pkg: overrides: let
        pkg' = if isFunction pkg then pkg core else pkg;
        deps = pkg'.dep-defaults or (_: {}) ({ pkgs = pkgsSelf; lib = lib'; inherit autoCall; } // overrides // platform);
      in pkg'.function (deps // platform);
    in foldlAttrs (acc: name: pkg: acc // { ${name} = autoCall pkg {}; }) {} dep.packages;

    /*
      Resolves the package set `dep` by recursively resolving its dependencies
      after which the set itself can be resolved with [`resolveDep`].

      `name` is the mapped name of the package set being resolved.
    */
    recurseDep = result: name: dep: let
      depRes = recurseIntoDeps result name dep.dependencies;
    in depRes // {
      ${name} = resolveDep depMappings.${name} name dep;
    };

    /*
      Resolves each package set in `deps`. `parent` is the mapped name of the
      package set depending on `deps`.
    */
    recurseIntoDeps = result: parent: deps:
      foldlAttrs (acc: name: value: recurseDep acc depMappings.${parent}.${name} value) result deps;

  /*
    The top-level resolution calls [`recurseIntoDeps`] to get a flattened list of
    the complete dependency tree for each package set. It then resolves all
    package sets by calling [`resolveDep`].
  */
  in foldlAttrs (acc: name: value: let
    setName = depMappings.root.${name};
    children = recurseIntoDeps acc setName value.dependencies;
    resolved = resolveDep depMappings.${setName} setName value;
  in children // { ${depMappings.root.${name}} = resolved; }) {} pkgSets;

  /*
    Bootstrap one more package sets into a set of packages for a given platform
    triple. This function makes it more easy to to construct a package set for
    any given combination of platform triples.

    The `strategy` takes a function that returns the attribute set listing the
    stages with their corresponding platform triple that should be constructed.
    The corresponding links between the different "platform triple package sets"
    are ensured through the `adjacent` attribute.

    # TODO: add example in doc
    # TODO: decide what the exact return value is, currently this is the stage
    # called `final`.
  */
  bootstrap = strategy: pkgSets: let
    # bootstrap constants
    mapping = depMapping pkgSets;
    lib = resolveLibs mapping pkgSets;
    crossResolver = resolvePkgs mapping lib pkgSets;

    # construct all package sets
    stages = builtins.mapAttrs (name: value: crossResolver value.adjacent value.triple) (strategy stages);

    # inverse mapping
    outputLib = foldlAttrs (acc: name: value: acc // { ${name} = lib.${value}; }) {} mapping.root;
    outputPkgs = foldlAttrs (acc: name: value: acc // { ${name} = stages.final.${value}; }) {} mapping.root;
  in { lib = outputLib; pkgs = outputPkgs; };
in {
  inherit depMapping resolveLibs resolvePkgs bootstrap;
}
