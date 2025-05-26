lib:
{
  function = {
    kaem,
    mescc-tools-extra,
    mkMinimalPackage,
    ...
  }: let
    inherit (lib.std.strings) optionalString makeBinPath;
  in {
    __functor = _: {
        name, # the name of the derivation
        text,
        executable ? false, # run chmod +x ?
        destination ? "", # relative path appended to $out eg "/bin/foo"
      }: mkMinimalPackage.onBuild {
        inherit name;
        version = "";
        drv = self: {
          inherit (self.public) text;
          passAsFile = [ "text" ];

          builder = "${kaem.onBuild}/bin/kaem";
          args = [
            "--verbose"
            "--strict"
            "--file"
            (builtins.toFile "write-text-file.kaem" (
              ''
                target=''${out}''${destination}
              ''
              # BUG: why only check "."?
              + optionalString (builtins.dirOf destination != ".") ''
                mkdir -p ''${out}''${destinationDir}
              ''
              + ''
                cp ''${textPath} ''${target}
              ''
              + optionalString executable ''
                chmod 555 ''${target}
              ''
            ))
          ];
          PATH = makeBinPath [ mescc-tools-extra.onBuild ];
          destinationDir = builtins.dirOf destination;
          inherit destination;
        };
        public = {
          inherit text;
          __elaborate = true; # NOTE: is this necessary?
        };
      };
    __elaborate = false;
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) mkMinimalPackage mescc-tools-extra kaem;
  };
}
