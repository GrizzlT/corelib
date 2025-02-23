{
  kaem,
  mescc-tools-extra,
}:
rec {
  writeTextFile =
    {
      name, # the name of the derivation
      text,
      executable ? false, # run chmod +x ?
      destination ? "", # relative path appended to $out eg "/bin/foo"
    }:
    derivation {
      inherit name text;
      passAsFile = [ "text" ];

      builder = "${kaem}/bin/kaem";
      system = "x86_64-linux";
      args = [
        "--verbose"
        "--strict"
        "--file"
        (builtins.toFile "write-text-file.kaem" (
          ''
            target=''${out}''${destination}
          ''
          + (if (builtins.dirOf destination == ".") then ''
            mkdir -p ''${out}''${destinationDir}
          '' else "")
          + ''
            cp ''${textPath} ''${target}
          ''
          + (if executable then ''
            chmod 555 ''${target}
          '' else "")
        ))
      ];

      PATH = [ "${mescc-tools-extra}/bin" ];
      destinationDir = builtins.dirOf destination;
      inherit destination;
    };

  writeText = name: text: writeTextFile { inherit name text; };

}
