core:
core.mkPackage {
  function = { writeTextFile, ... }: {
    __functor = self: name: text: writeTextFile { inherit name text; };
    noSplice = true;
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (pkgs.self) writeTextFile;
  };
}
