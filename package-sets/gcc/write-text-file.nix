lib:
{
  function = {
    bash,
    coreutils,
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

          builder = "${bash.onBuild}/bin/bash";
          args = [
            (builtins.toFile "write-text-file.sh" (
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
          PATH = makeBinPath [ coreutils.onBuild ];
          destinationDir = builtins.dirOf destination;
          inherit destination;
        };
        public = {
          inherit text;
          __elaborate = false; # NOTE: is this necessary?
        };
      };
    __elaborate = false;
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) bash coreutils;
    inherit (pkgs.stage0) mkMinimalPackage;
  };
}
