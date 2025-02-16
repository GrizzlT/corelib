lib:

let
  # Adds bin folders under packages in [`$binaries`] to `PATH`.
  binariesToPath = /* bash */ ''
    for i in $binaries; do
      if [ "$i" = / ]; then i=; fi
      addToSearchPath PATH "$i/bin"
    done
    unset i
    nixWarnLog "path: $PATH"
  '';

in {
  phases = {
    inherit binariesToPath;
  };
}
