{
  packages = {
    bootstrapFiles = import ./bootstrap-files;

    boot-bash = import ./bootstrap-tools/bash.nix;
    bootstrapTools = import ./bootstrap-tools;
    runCommand = import ./run-command.nix;

    python = import ./python.nix;
    m4 = import ./m4.nix;
    bison = import ./bison.nix;
    binutils = import ./binutils.nix;
    glibc-boot = import ./glibc-boot.nix;
  };

  lib = self': {
    self = import ./lib self';
    std = import ../stdlib/default.nix self'.std;
  };

  dependencies = {
    stage0 = import ../stage0-posix;
  };
}
