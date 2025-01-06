let
  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

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
in
  consumePkgs
