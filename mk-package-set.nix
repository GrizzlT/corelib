let
  # util = import ./lib.nix;

  # TODO: provide some minimal utilities for package definition
  # this mostly serves to provide override hooks
  core = {};

  # combineOverride = f: g: self: super: let
  #   fApplied = f self super;
  #   super' = super // { self = super.self // fApplied; };
  # in fApplied // g self super';
  # in prev' // (g (prev // { self = prev.self // prev'; }));

  combinePkgs = f: g: self: let
    prev = f self;
  in prev // g (self // prev);

  /**
    # Actual implementation

    Creates a set with three main attributes:

    - `packages`: Attribute set of package definitions,
      contains both recipes and dependency defaults. This is basically anything
      that depends on the build platform.

    - `lib`: Attribute set of pure functions, these do not depend on a platform

    - `dependencies`: Attribute set of the dependency package sets

    To allow for overrides within a package set scope:

    - `withDeps`: Allow overriding or adding dependencies to this package set.

    # TODO: Apply extensions
    - `withExtension`: Allow modifying the packages in this set.

    - `withPackages`: Extra packages to include in the set.

    - `withLib`: Extra pure functions to include in the set.

    - `customize`: Allows to set both dependencies and package extensions.
  */
  mkPackageSet = { packages ? (_: {}), lib ? (_: {}), dependencies ? {} }: let
    withFunctors = raw: let
      __original = raw // (createFunctors packages lib dependencies []);

      createFunctors = pkgs: libs: deps: exts: let
        withDeps = extraDeps: raw //
          (createFunctors pkgs libs (deps // extraDeps) exts);

        withExtension = extension: raw //
          (createFunctors pkgs libs deps (exts ++ [extension]));

        withPackages = packages: raw //
          (createFunctors (combinePkgs pkgs packages) libs deps exts);

        # NOTE: is this necessary?
        withLib = lib: raw //
          (createFunctors pkgs (libs // lib) deps exts);

        customize = { packages ? (_: {}), extensions ? [], dependencies ? {}, lib ? {} }: raw //
          (createFunctors (combinePkgs pkgs packages) (exts ++ extensions) (deps // dependencies) (libs // lib));

        # apply = pkgs: depMappings: let
        #   toFix = self: let
        #     pkgsArg = this: let
        #       pkgsSelf = pkgs // { self = this; };
        #       pkgsInput = builtins.foldl' (acc: mapping: acc // { ${mapping.name} = acc.${mapping.depName}; }) pkgsSelf depMappings;
        #     in pkgsInput;
        #
        #     resolved = builtins.mapAttrs (_: pkg: pkg { pkgs = pkgsArg self; }) packages;
        #   in resolved // pkgExt (pkgsArg resolved);
        # in fix toFix;
        #
        packages = builtins.mapAttrs (_: value: value core) (pkgs packages);
      in {
        inherit withDeps withExtension withPackages withLib customize;
        inherit __original;
        dependencies = deps;
        inherit packages;
        lib = libs;
        extensions = exts;
      };

    in __original;

  in withFunctors {};
in
  mkPackageSet
