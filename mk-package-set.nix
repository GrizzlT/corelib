let
  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  fix = f: let x = f x; in x;


  # TODO: apply overrides
  mkPackageSet = { packages, dependencies ? {}, overrides ? {} }: {
    # Return the packages in this set resolved in their ddependency context
    apply = pkgs: depMappings: let
      toFix = self: let
        pkgsSelf = pkgs // { inherit self; };
        pkgsInput = builtins.foldl' (acc: mapping: acc // { ${mapping.name} = acc.${mapping.depName}; }) pkgsSelf depMappings;
        resolved = builtins.mapAttrs (_: pkg: pkg { pkgs = pkgsInput; }) packages;
      in resolved;
    in fix toFix;

    # TODO: apply overrides
    allDeps = foldlAttrs (acc: depName: dep: acc ++ dep.allDeps ++ [{ name = depName; inherit dep; }]) [] dependencies;

    allOverrides = foldlAttrs (acc: _: dep: acc ++ dep.allOverrides) [] dependencies
      ++ (if builtins.length (builtins.attrValues overrides) == 0 then [] else [overrides]);
  };
in
  mkPackageSet
