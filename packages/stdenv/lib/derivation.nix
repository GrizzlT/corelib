lib:

let
  inherit (lib.self) isFunction fix extends composeExtensions genAttrs;

  /*
    ## Construct an empty package fixpoint.

    The resulting attribute set is equipped with an extension function
    `addLayer`. This function extends the fixpoint with an overlay.
    All package attributes are exported in `internals` in the final output. Any
    attribute in `public` is also exported directly.

    ### Example
    The following:
    ```nix
      mkPackage (self: {
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
  */
  mkPackage = init: let
    build = self: init self;

    withExtraAttrs = prevLayer: raw: let
      finalOverride = (self: super: {
        public = super.public // {
          addLayer = layer: withExtraAttrs (composeExtensions prevLayer layer) raw;
        };
      });
      result = fix (extends (composeExtensions prevLayer finalOverride) raw);
    in result.public;
  in withExtraAttrs (self: super: { public = super.public or {} // { internals = self; }; }) build;

  /*
    ## Construct a derivation fixpoint.

    The resulting attribute set computes a derivation. The input attribute `drvAttrs`
    are passed directly to `derivationStrict` and the resulting outputs are exported
    directly to `public`.

    Any other input attributes are included in the package fixpoint for later use.
  */
  mkDrv = drvInit: mkPackage (self: let
    init = if isFunction drvInit then drvInit self else drvInit;
    outputs = genAttrs (self.drvAttrs.outputs) (
      outputName: self.public // {
        outPath = self.drvOutAttrs.${outputName};
        inherit outputName;
        outputSpecified = true;
      }
    );
  in (builtins.removeAttrs [ "drvAttrs" ] init) // {
    drvAttrs = { outputs = [ "out" ]; } // init.drvAttrs;
    drvOutAttrs = builtins.derivationStrict self.drvAttrs;
    public = init.public // {
      type = "derivation";
      inherit (self.drvAttrs) name;
      outPath = self.drvOutAttrs.${self.public.outputName};
      outputName = builtins.head self.drvAttrs.outputs;
      drvPath = self.drvOutAttrs.drvPath;
    } // outputs;
  });
in
{
  inherit mkPackage mkDrv;
}
