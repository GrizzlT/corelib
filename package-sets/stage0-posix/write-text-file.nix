core:
core.mkPackage {
  function = { std, kaem, mescc-tools-extra, mkMinimalPackage, ... }: let
    inherit (std.strings) optionalString makeBinPath;
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
          noSplice = true; # NOTE: is this necessary?
        };
      };
    noSplice = true;
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (pkgs.self) mkMinimalPackage mescc-tools-extra kaem;
  };
}
