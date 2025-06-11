{ std, ... }:
let
  inherit (std.attrsets) genAttrs optionalAttrs removeAttrs isDerivation attrByPath;

  inherit (std.derivations) encapsulateLayers;

  inherit (std.lists) head;

  inherit (std.strings) sanitizeDerivationName splitString makeBinPath;

  inherit (std.trivial) isFunction mapNullable;

in {
  composeBuild = layers: topAttrs:
    encapsulateLayers ((builtins.map (l: l topAttrs) layers) ++ [(self: super: {
      __topAttrs = topAttrs;
    })]);

  layers = {



    /**
      Entrypoint for name-version coupled packages. Version is null
      by default. A name is required.
     */
    package = { name, version ? null, public ? {}, ... }@topAttrs: (self: super: {
      package = topAttrs.package or {} // {
        inherit name version;
      };
      public = super.public or {} // {
        inherit name version;
      } // (if isFunction public then public self else public);
    });




    /**
      Processing layer that checks and sanitizes derivation attributes from the
      `drvAttrs` attribute set in the fixpoint. The derivation outputs are
      added to `public`.
     */
    derivation = _: (self: super: let
      outputs = genAttrs (self.drvAttrs.outputs) (
        outputName: self.public // {
          inherit outputName;
          outPath = self.drvOutAttrs.${outputName};
          outputSpecified = true;
        }
      );

      pkgName = "${self.package.name}${
        if (self.package.version != null && self.package.version != "") then
          "-${self.package.version}"
        else
          ""
      }";

      # Turn a derivation into its outPath without a string context attached.
      # See the comment at the usage site.
      unsafeDerivationToUntrackedOutpath = drv:
        if isDerivation drv && (!drv.__contentAddressed or false)
        then builtins.unsafeDiscardStringContext drv.outPath
        else drv;

      makeOutputChecks = attrs:
        # If we use derivations directly here, they end up as build-time dependencies.
        # This is especially problematic in the case of disallowed*, since the disallowed
        # derivations will be built by nix as build-time dependencies, while those
        # derivations might take a very long time to build, or might not even build
        # successfully on the platform used.
        # We can improve on this situation by instead passing only the outPath,
        # without an attached string context, to nix. The out path will be a placeholder
        # which will be replaced by the actual out path if the derivation in question
        # is part of the final closure (and thus needs to be built). If it is not
        # part of the final closure, then the placeholder will be passed along,
        # but in that case we know for a fact that the derivation is not part of the closure.
        # This means that passing the out path to nix does the right thing in either
        # case, both for disallowed and allowed references/requisites, and we won't
        # build the derivation if it wouldn't be part of the closure, saving time and resources.
        # While the problem is less severe for allowed*, since we want the derivation
        # to be built eventually, we would still like to get the error early and without
        # having to wait while nix builds a derivation that might not be used.
        # See also https://github.com/NixOS/nix/issues/4629
        optionalAttrs (attrs ? disallowedReferences) {
          disallowedReferences =
            map unsafeDerivationToUntrackedOutpath attrs.disallowedReferences;
        } //
        optionalAttrs (attrs ? disallowedRequisites) {
          disallowedRequisites =
            map unsafeDerivationToUntrackedOutpath attrs.disallowedRequisites;
        } //
        optionalAttrs (attrs ? allowedReferences) {
          allowedReferences =
            mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedReferences;
        } //
        optionalAttrs (attrs ? allowedRequisites) {
          allowedRequisites =
            mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedRequisites;
        };
    in
      {
        drvAttrs = { outputs = [ "out" ]; }
          // (optionalAttrs (self ? package) {
            name = pkgName;
          })
          // super.drvAttrs or {};

        drvOutAttrs =
          # Policy on acceptable hash types in nixpkgs/corelib
          assert self.drvAttrs ? outputHash -> (
            let algo =
              self.drvAttrs.outputHashAlgo or (head (splitString "-" self.drvAttrs.outputHash));
            in
            if algo == "md5" then
              throw "Rejected insecure ${algo} hash '${self.drvAttrs.outputHash}'"
            else
              true
          );
        builtins.derivationStrict ({
          name = sanitizeDerivationName self.drvAttrs.name;
        }
          // (makeOutputChecks self.drvAttrs)
          // (removeAttrs self.drvAttrs [
            "name"
            "allowedReferences"
            "allowedRequisites"
            "disallowedReferences"
            "disallowedRequisites"
          ]));

        # make derivation more lazy
        public = super.public or {} // {
          type = "derivation";
          outPath = self.drvOutAttrs.${self.public.outputName};
          outputName = head self.drvAttrs.outputs;
          drvPath = self.drvOutAttrs.drvPath;
        } // outputs;
      });



      /**
        Set the PATH environment variable for the build.
        This can be tailored to each builder's favorite attribute according to
        `${path}`.

        setPathEnv :: [String] -> AttrSet -> (AttrSet -> AttrSet -> AttrSet)
       */
      setPathEnv = path: topAttrs: (self: super: {
        drvAttrs = super.drvAttrs or {} // {
          PATH = makeBinPath (attrByPath path [] topAttrs);
        };
      });
  };
}
