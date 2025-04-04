lib:
let

  inherit (lib.self.trivial)
    isFunction
    ;
  inherit (lib.self.strings)
    sanitizeDerivationName
    ;

  inherit (lib.self.fixed-points)
    composeExtensions
    extends
    fix
    ;

  inherit (lib.self.lists)
    foldl'
    head
    ;

  inherit (lib.self.attrsets)
    genAttrs
    optionalAttrs
    ;

  inherit (lib.self.derivations)
    mkEncapsulate
    ;

in {

  /**
    ## Construct an encapsulated fixpoint.

    The resulting fixpoint attribute set is equipped with an extension function
    `addLayer`. This function extends the fixpoint with an overlay.
    All fixpoint attributes are exported in `internals` in the final result. Any
    attribute in `public` is exported directly.

    ### Example
    The following:
    ```nix
      mkEncapsulate (self: {
        public.name = "${self.pname}-${self.version}";
        pname = "package";
        version = "0.1.0";
      })
    ```
    will result in
    ```nix
      {
        addLayer = <function>;
        internals = {
          pname = "package";
          version = "0.1.0";
          public = { # repeated final attribute set };
        };
        name = "package-0.1.0"
      }
    ```
    = Performance

    The `addLayer` lives outside of the fixpoint. This means multiple layers are
    first merged into one by means of `composeExtensions`. I believe this reuses
    "intermediate results" in between overlay layers. The fixpoint is only
    calculated when other attributes are evaluated. The main consequence of this
    performance measure currently is the inability to use `addLayer` inside of
    the fixpoint. This could be added in the future but awaits a valid use case.

  */
  mkEncapsulate = init: let
    build = self: if isFunction init then init self else init;

    withExtraAttrs = prevLayer: raw: let
      result = fix (extends prevLayer raw);
    in result.public // {
      addLayer = layer: withExtraAttrs (composeExtensions prevLayer layer) raw;
    };
  in withExtraAttrs (self: super: {
    public = super.public or {} // { internals = self; };
  }) build;

  /**
    ## Construct a layered encapsulated fixpoint

    Adds `layers` successively to an empty [`mkEncapsulate`] through `addLayer`.
  */
  encapsulateLayers = layers:
    foldl' (acc: layer: acc.addLayer layer) (mkEncapsulate {}) layers;

  layers = {
    package = { name, version, ... }@attrs: (self: super: {
      package = attrs;
      public = super.public or {} // {
        inherit name version;
      };
    });

    derivation = attrInit: (self: super: let
      attrs = if isFunction attrInit then attrInit self else attrInit;

      outputs = genAttrs (self.drvAttrs.outputs) (
        outputName: self.public // {
          inherit outputName;
          outPath = self.drvOutAttrs.${outputName};
          outputSpecified = true;
        }
      );
    in {
      drvAttrs = { outputs = [ "out" ]; }
        // attrs
        // (optionalAttrs (attrs ? name || self ? package) {
          name = sanitizeDerivationName attrs.name or "${self.package.name}-${self.package.version}";
      });
      drvOutAttrs = builtins.derivationStrict self.drvAttrs;
      # make derivation more lazy
      public = super.public or {} // {
        type = "derivation";
        outPath = self.drvOutAttrs.${self.public.outputName};
        outputName = head self.drvAttrs.outputs;
        drvPath = self.drvOutAttrs.drvPath;
      } // outputs;
    });
  };
}
