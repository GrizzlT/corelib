let
  inherit (import ./lib.nix) foldlAttrs;

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

  resolveLibs = depMappings: pkgSets: let
    resolveDep = result: mappings: dep: let
      lib = foldlAttrs (acc: name: value: acc // { ${name} = result.${value}; }) {} mappings;
      resolved = dep.lib (lib // { self = resolved; });
    in resolved;

    recurseDep = result: name: dep: let
      depRes = recurseIntoDeps result name dep.dependencies;
    in depRes // {
      ${name} = resolveDep depRes depMappings.${name} dep;
    };

    recurseIntoDeps = result: parent: deps:
      foldlAttrs (acc: name: value: recurseDep acc depMappings.${parent}.${name} value) result deps;

  in foldlAttrs (acc: name: value: let
      setName = depMappings.root.${name};
      children = recurseIntoDeps acc setName value.dependencies;
      resolved = resolveDep children depMappings.${setName} value;
    in children // { ${depMappings.root.${name}} = resolved; }) {} pkgSets;

  # TODO: create function for easy cross-compile setup
  #
  /* e.g.
    bootstrap (self: {
      3native = { pkgsBuildBuild = self.3native; ... };
      2nativeForeign = { pkgsBuildBuild = self.3native; ... };
    })
  */
  resolvePkgs = depMappings: lib: pkgSets:
    { pkgsBuildBuild, pkgsBuildHost, pkgsBuildTarget, pkgsHostHost, pkgsHostTarget, pkgsTargetTarget }@triples:
    { hostPlatform, buildPlatform, targetPlatform }@platform: # Add custom args here
  let
    # NOTE: filter out nulls is possible
    buildFromTriple = depName: pkgName: host: target: let
      triple = triples.${"pkgs" + host + target};
    in if triple.${depName} ? ${pkgName} then let pkg = triple.${depName}.${pkgName}; in
      if pkg.targetPlatform or null == null then { ${"on" + host} = pkg; }
      else { ${"on" + host + "For" + target} = pkg; }
    else {};

    spliceDep = depName: pkgNames: let
      spliced = builtins.foldl' (acc: pkg: let
        splicer = buildFromTriple depName pkg;
      in acc // { ${pkg} =
        (splicer "Build" "Build") //
        (splicer "Build" "Host") //
        (splicer "Build" "Target") //
        (splicer "Host" "Host") //
        (splicer "Host" "Target") //
        (splicer "Target" "Target");
      }) {} pkgNames;
    in spliced;

    resolveDep = mappings: depName: dep: let
      lib' = (foldlAttrs (acc: name: value: acc // { ${name} = lib.${value}; }) {} mappings) // { self = lib.${depName}; };
      pkgs = foldlAttrs (acc: name: value: acc // { ${name} = spliceDep mappings.${name} (builtins.attrNames value.packages); }) {} dep.dependencies;
      pkgsSelf = pkgs // { self = spliceDep depName (builtins.attrNames dep.packages); };
    in foldlAttrs (acc: name: pkg: let
      deps = pkg.dep-defaults or (_: {}) ({ pkgs = pkgsSelf; lib = lib'; } // platform);
    in acc // {
      ${name} = pkg.function (deps // platform);
    }) {} dep.packages;

    recurseDep = result: name: dep: let
      depRes = recurseIntoDeps result name dep.dependencies;
    in depRes // {
      ${name} = resolveDep depMappings.${name} name dep;
    };

    recurseIntoDeps = result: parent: deps:
      foldlAttrs (acc: name: value: recurseDep acc depMappings.${parent}.${name} value) result deps;
  in foldlAttrs (acc: name: value: let
    setName = depMappings.root.${name};
    children = recurseIntoDeps acc setName value.dependencies;
    resolved = resolveDep depMappings.${setName} setName value;
  in children // { ${depMappings.root.${name}} = resolved; }) {} pkgSets;
in {
  inherit depMapping resolveLibs resolvePkgs;
}
