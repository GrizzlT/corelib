let
  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  # TODO: add overrides
  mkPackageSet = { packages, dependencies ? {} }: {
    # Return the packages in this set resolved in their ddependency context
    # TODO: add dependency mappings
    apply = pkgs: depMappings: let
      pkgsSelf = pkgs // { self = resolved; };
      pkgsInput = builtins.foldl' (acc: mapping: acc // { ${mapping.name} = acc.${mapping.depName}; }) pkgsSelf depMappings;
      resolved = builtins.mapAttrs (_: pkg: pkg { pkgs = pkgsInput; }) packages;
    in resolved;

    # TODO: apply overrides
    allDeps = foldlAttrs (acc: depName: dep: acc ++ dep.allDeps ++ [{ name = depName; inherit dep; }]) [] dependencies;
  };
in
  mkPackageSet
