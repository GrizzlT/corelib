lib:

let
  isFunction = f: builtins.isFunction f ||
    (f ? __functor && isFunction (f.__functor f));

  composeExtension = f: g: self: super: let
    fApplied = f self super;
    super' = super // fApplied;
  in fApplied // g self super';

  fix = f: let x = f x; in x;
  extends = overlay: f: (self: let
    super = f self;
  in super // overlay self super);

  genAttrs =
    names:
    f:
    builtins.listToAttrs (map (n: { name = n; value = f n; }) names);

  mkPackage = init: let
    build = self: init self;

    withExtraAttrs = prevLayer: raw: let
      result = fix (extends prevLayer raw);
    in result.public // {
      addLayer = layer: withExtraAttrs (composeExtension prevLayer layer) raw;
    };
  in withExtraAttrs (self: super: { public = super.public // { internals = self; }; }) build;

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
    drvAttrs = { outputs = [ "out" ]; } // (builtins.removeAttrs args [ "public" ]);
    drvOutAttrs = builtins.derivationStrict self.drvAttrs;
    public = rec {
      type = "derivation";
      outPath = self.drvOutAttrs.${outputName};
      outputName = lib.head self.drvAttrs.outputs;
      drvPath = self.drvOutAttrs.drvPath;
    } // outputs // args.public;
  });
in {
  customisation = { inherit composeExtension fix extends; };

  inherit isFunction;

  inherit mkDrv mkPackage;
}
