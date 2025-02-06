lib: let
  isFunction = f: builtins.isFunction f ||
    (f ? __functor && isFunction (f.__functor f));
in {
  inherit isFunction;
}
