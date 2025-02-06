lib: let
  genAttrs =
    names:
    f:
    builtins.listToAttrs (map (n: { name = n; value = f n; }) names);
in {
  inherit genAttrs;
}
