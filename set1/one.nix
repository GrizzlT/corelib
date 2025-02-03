# Minimal set of utilities provided by `mkPackageSet`.
core:
{
  # The package recipe function -> returns derivation
  function = { two, three, args, ... }: {
    value = two.onHost.value + 2;
    child = three.onHost.value;
    inherit args;
  };
  # This package has a dependency, defaults have to be specified.
  dep-defaults = { pkgs, lib, ... }@args: {
    inherit (pkgs.self) two; # This dependency is from the same package set.
    inherit (pkgs.std) three;
    args = pkgs;
  };
}

# core
# TODO: provide overrideInput thing
# do this when resolving -> uniform overrideInput, once from core, once in the
# derivation result
# TODO: provide overrideLayer thing

# mkPackage
# TODO: provide overrideLayer thing
# encapsulation?? -> base layer is publicly exported as `internals`?.
