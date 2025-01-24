let
  inherit (import ./lib.nix) foldlAttrs genAttrs;

  # result -> recursively add to result with mappings for each dependency,
  # only returns the functions in the `lib` of `pkgSet`.
  resolveLib = pkgSet: let
    resolveDep = result: mappings: dep: let
      lib = foldlAttrs (acc: name: value: acc // { ${name} = result.${value}; }) {}
            ((genAttrs (builtins.attrNames dep.dependencies) (n: n)) // mappings);

      resolved = dep.lib (lib // { self = resolved; });
    in resolved;

    # result = attrset with lib, counter
    recurseDep = result: name: dep: let
      depRes = recurseIntoDeps result dep.dependencies;

      needsMapping = depRes.lib ? ${name};
      counter = if needsMapping then depRes.counter + 1 else depRes.counter;
      depName = if needsMapping then name + "_dep_${toString depRes.counter}" else name;
    in {
      return = {
        inherit counter;
        lib = depRes.lib // {
          ${depName} = resolveDep depRes.lib depRes.mappings dep;
        };
      };
      mapping = if needsMapping then {
        ${name} = depName;
      } else {};
    };

    # returns lib, counter, mappings
    recurseIntoDeps = result: deps: let
      depRes = foldlAttrs (acc: name: value: let
        resolved = recurseDep acc.inner name value;
      in { inner = resolved.return; mappings = acc.mappings // resolved.mapping; }) { inner = result; mappings = {}; } deps;
    in depRes.inner // { inherit (depRes) mappings; };

    mainComputed = recurseIntoDeps { counter = 0; lib = {}; } pkgSet.dependencies;
  in resolveDep mainComputed.lib mainComputed.mappings pkgSet;

  consumePkgs = pkgSets: let
    expanded = builtins.mapAttrs (_: v: { pkg = v; deps = v.allDeps; }) pkgSets;

    applyDep = meta: name: dep: let
      needsMapping = meta.pkgs ? ${name};
      counter = if needsMapping then meta.counter + 1 else meta.counter;
      depName = if needsMapping then name + "_dep_${toString meta.counter}" else name;
    in {
      inherit counter;
      pkgs = meta.pkgs // {
        ${depName} = dep.apply meta.pkgs meta.depMappings;
      };
      depMappings = meta.depMappings ++ (if needsMapping then [{
        inherit name depName;
      }] else []);
    };

    consumed = foldlAttrs (meta: name: set: meta // (let
      depsResult = builtins.foldl' (meta2: dep: applyDep meta2 dep.name dep.dep) (meta // { depMappings = []; }) set.deps;

      needsMapping = meta.pkgs ? ${name};
      counter = if needsMapping then depsResult.counter + 1 else depsResult.counter;
      pkgName = if needsMapping then name + "_pkg_${toString depsResult.counter}" else name;
    in {
      inherit counter;
      pkgs = meta.pkgs // {
        ${pkgName} = set.pkg.apply depsResult.pkgs depsResult.depMappings;
      };
    })) { counter = 0; pkgs = {}; } expanded;

  in consumed;
in {
  inherit consumePkgs resolveLib;
}
