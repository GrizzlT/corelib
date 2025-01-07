let
  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  fix = f: let x = f x; in x;
  combineOverride = f: g: prev: let
    prev' = f prev;
  in g (prev // { self = prev.self // prev'; });

  # TODO: apply overrides
  mkPackageSet = { packages, dependencies ? {} }: let
    withFunctors = raw: let
      createFunctors = pkgOverride: depOverrides: let
        __original = _: raw // (createFunctors (_: {}) dependencies);

        allDeps = foldlAttrs (acc: depName: dep: acc ++ dep.allDeps ++ [{ name = depName; inherit dep; }]) [] depOverrides;
        withDepsOverride = override: raw //
          (createFunctors pkgOverride (depOverrides // override));

        withOverride = override: raw //
          (createFunctors (combineOverride pkgOverride override) depOverrides);

        apply = pkgs: depMappings: let
          toFix = self: let
            pkgsArg = this: let
              pkgsSelf = pkgs // { self = this; };
              pkgsInput = builtins.foldl' (acc: mapping: acc // { ${mapping.name} = acc.${mapping.depName}; }) pkgsSelf depMappings;
            in pkgsInput;

            resolved = builtins.mapAttrs (_: pkg: pkg { pkgs = pkgsArg self; }) packages;
          in resolved // pkgOverride (pkgsArg resolved);
        in fix toFix;

      in {
        inherit withOverride apply __original withDepsOverride allDeps;
        dependencies = depOverrides;
      };
    in raw // createFunctors (_: {}) dependencies;
  in withFunctors {
    inherit packages;
  };
in
  mkPackageSet
