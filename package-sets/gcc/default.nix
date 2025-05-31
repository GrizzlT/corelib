{
  packages = {
    bootstrapFiles = import ./bootstrap-files;

    boot-bash = import ./bootstrap-tools/bash.nix;

    bootstrapTools = import ./bootstrap-tools;
  };

  lib = self': {
    std = import ../stdlib/default.nix self'.std;
  };

  dependencies = {
    stage0 = import ../stage0-posix;
  };
}
