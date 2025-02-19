let
  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  genAttrs =
    names:
    f:
    builtins.listToAttrs (map (n: { name = n; value = f n; }) names);

  fix = f: let x = f x; in x;

  composeExtensions = f: g: self: super: let
    fApplied = f self super;
    super' = super // fApplied;
  in fApplied // g self super';

  isFunction = f: builtins.isFunction f ||
    (f ? __functor && isFunction (f.__functor f));

  makeOverridable = f: origArgs: let
    origRes = f origArgs;
  in origRes // { overrideInputs = newArgs: makeOverridable f (origArgs // newArgs); };

  mkPackage = pkgDef: let
    withFunctors = prevLayer: deps: let
      resolvedFn = args: let
        pkgRes = pkgDef.function args;
      in if pkgRes ? addLayer then
        pkgRes.addLayer prevLayer
      else let
        final = prevLayer pkgRes final;
      in final;
    in {
      function = args: makeOverridable resolvedFn args;
      dep-defaults = args: (pkgDef.dep-defaults args) // (deps args);

      overrideInputs = newArgs: let
        newDeps = args: if isFunction newArgs then (deps args) // (newArgs args) else (deps args) // newArgs;
      in withFunctors prevLayer newDeps;

      addLayer = layer: let
        newLayer = self: super: if isFunction layer then layer self super else layer;
      in withFunctors (composeExtensions prevLayer newLayer) deps;
    };
  in withFunctors (self: super: {}) (args: {});
in
{
  inherit foldlAttrs genAttrs fix isFunction;

  # TODO: add override semantics
  core = {
    inherit mkPackage;
  };
}
