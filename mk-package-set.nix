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
      createFunctors = override0: let
        __original = _: raw // (createFunctors (_: {}));
        withOverride = override: raw //
          (createFunctors (combineOverride override0 override));
        apply = pkgs: depMappings: let
          toFix = self: let
            pkgsArg = this: let
              pkgsSelf = pkgs // { self = this; };
              pkgsInput = builtins.foldl' (acc: mapping: acc // { ${mapping.name} = acc.${mapping.depName}; }) pkgsSelf depMappings;
            in pkgsInput;

            resolved = builtins.mapAttrs (_: pkg: pkg { pkgs = pkgsArg self; }) packages;
          in resolved // override0 (pkgsArg resolved);
        in fix toFix;
      in { inherit withOverride apply __original; };
    in raw // createFunctors (_: {});
  in withFunctors {
    inherit packages dependencies;

    # TODO: apply overrides
    allDeps = foldlAttrs (acc: depName: dep: acc ++ dep.allDeps ++ [{ name = depName; inherit dep; }]) [] dependencies;
  };
in
  mkPackageSet
