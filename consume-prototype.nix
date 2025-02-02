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
  inherit consumePkgs depMapping resolveLibs;
}
