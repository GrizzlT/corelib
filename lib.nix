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

  isFunction = f: builtins.isFunction f ||
    (f ? __functor && isFunction (f.__functor f));
in
{
  inherit foldlAttrs genAttrs fix isFunction;

  core = {};
}
