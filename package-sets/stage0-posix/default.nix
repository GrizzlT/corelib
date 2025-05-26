let
  stage0 = {
    packages = {
      fetchurl = import ./bootstrap-fetchurl.nix;
      mkMinimalPackage = import ./mk-minimal-package.nix;

      ## Stage 0 posix
      minimal-bootstrap-sources = import ./bootstrap-sources.nix;

      hex0 = import ./hex0.nix;
      mescc-tools-boot = import ./mescc-tools-boot.nix;
      mescc-tools-boot2 = import ./mescc-tools-boot2.nix;
      mescc-tools = import ./mescc-tools;
      mescc-tools-extra = import ./mescc-tools-extra;

      writeText = import ./write-text.nix;
      writeTextFile = import ./write-text-file.nix;
      kaem = import ./kaem;
      runCommand = import ./run-command2.nix;

      ## GCC bootstrap
    };

    lib = self': {
      self = import ./lib self';
      std = import ../stdlib/default.nix self'.std;
    };
  };
in
  stage0
