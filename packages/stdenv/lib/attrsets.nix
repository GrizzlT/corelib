lib: let
  genAttrs =
    names:
    f:
    builtins.listToAttrs (map (n: { name = n; value = f n; }) names);

  foldlAttrs = f: init: set:
    builtins.foldl'
      (acc: name: f acc name set.${name})
      init
      (builtins.attrNames set);

  optionalAttrs =
    cond:
    as:
    if cond then as else {};
in {
  inherit genAttrs foldlAttrs optionalAttrs;
}
