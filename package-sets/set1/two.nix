# Library function provided by the package set
lib:
{
  # The package recipe function -> returns derivation
  # This gets cross-compiled.
  function = { runPlatform, targetPlatform, ... }: {
    # Platform-specific rules are easy to apply
    value = if runPlatform == targetPlatform then 10 else 9;
    inherit runPlatform targetPlatform;
  };
}
