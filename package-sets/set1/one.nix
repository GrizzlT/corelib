# Library function provided by the package set
lib:
{
  # The package recipe function -> can return derivation
  # This gets cross-compiled.
  function = { two, ... }: {
    value = two.onBuildForRun.value + 2;
    libTest = lib.fn2;
  };

  # This package has a dependency, defaults have to be specified.
  inputs = { pkgs, ... }: {
    inherit (pkgs.self) two; # This dependency is from the same package set.
  };
}

