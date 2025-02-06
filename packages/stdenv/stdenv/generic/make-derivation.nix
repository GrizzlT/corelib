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
  in withExtraAttrs (self: super: { public = super.public // { internals = self; }; }) build;

  /*
    ## Construct a derivation fixpoint.

    The resulting attribute set computes a derivation. The input arguments are
    passed directly to `derivationStrict` and the resulting outputs are exported
    directly to `public`.

    Attributes in `extraAttrs` are added to the fixpoint directly (i.e. are
    internal) and attributes in `public` are added to `public`.
  */
  mkDrv = drvInit: mkPackage (self: let
    args = if isFunction drvInit then drvInit self else drvInit;
    outputs = genAttrs (self.drvAttrs.outputs) (
      outputName: self.public // {
        outPath = self.drvOutAttrs.${outputName};
        inherit outputName;
        outputSpecified = true;
      }
    );
  in {
    finalPackage = self.public;
    drvAttrs = { outputs = [ "out" ]; } // (builtins.removeAttrs args [ "public" "extraAttrs" ]);
    drvOutAttrs = builtins.derivationStrict self.drvAttrs;
    public = rec {
      type = "derivation";
      inherit (self.drvAttrs) name;
      outPath = self.drvOutAttrs.${outputName};
      outputName = builtins.head self.drvAttrs.outputs;
      drvPath = self.drvOutAttrs.drvPath;
    } // outputs // args.public;
  } // args.extraAttrs or {});

  /*
    ## WIP, shows how a bootstrap process could look like.
  */
  mkDerivationFromStdenv =
    stdenv:

    let
      mkDerivation = fnOrAttrs:
        lib.self.mkDrv (self: let
          setup = if lib.self.isFunction fnOrAttrs then fnOrAttrs self else fnOrAttrs;
        in setup
          // (if (setup ? name  || (setup ? pname && setup ? version)) then {
            name = if setup ? setup.name then setup.name else "${setup.pname}-${setup.version}";
          } else {})
          // {
            builder = setup.realBuilder or stdenv.shell;
            args = setup.args or ["-e" (setup.builder or ./default-builder.sh)];
            inherit stdenv;

            # inherit (stdenv.buildPlatform) system;
            system = stdenv.buildPlatform;

            public = { inherit (stdenv) buildPlatform hostPlatform targetPlatform; };
            extraAttrs.setup = setup;
          });
    in mkDerivation;
in
{
  inherit mkPackage mkDrv mkDerivationFromStdenv;
}
