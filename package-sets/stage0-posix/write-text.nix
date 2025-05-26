lib:
{
  function = { writeTextFile, ... }: {
    __functor = self: name: text: writeTextFile { inherit name text; };
    __elaborate = false;
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) writeTextFile;
  };
}
