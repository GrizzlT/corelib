let
  globalLib = self': {
    self = import ./lib self';
    std = import ../stdlib/default.nix self'.std;
  };
  globalDependencies = {
    stage0 = import ../stage0-posix;
  };

  inheritPackage = expr: {
    function = expr;
    inputs = args: args.pkgs;
  };
  overrideRecipe = pkg: override: (lib: let
    pkg' = if builtins.isFunction pkg then pkg lib else pkg;
  in {
    inherit (pkg') function;
    inputs = { pkgs, ... }@args: (pkg'.inputs args) // (override args);
  });

  stageInit = stages: builtins.foldl' (prev: stage: {
    packages = stage prev.packages or {};
    dependencies = globalDependencies // {
      previous = prev;
    };
    lib = globalLib;
  }) {} stages;

in

stageInit [
  # Extract first bash and set up bootstrapTools
  (
    { }: {
      bootstrapFiles = import ./bootstrap-files;
      bootstrapTools = import ./bootstrap-tools;

      bash = import ./bootstrap-tools/bash.nix;

      runCommand = overrideRecipe (import ./run-command.nix) (args: {
        writeText = args.pkgs.stage0.writeText;
      });
    }
  )

  # Extract first few bootstrap Tools
  (
    prevStage: {
      bootstrapFiles = import ./bootstrap-files;
      bootstrapTools = import ./bootstrap-tools;

      bash = inheritPackage (args: args.previous.bootstrapTools.__elaborate.bash.onRun);
      coreutils = inheritPackage (args: args.previous.bootstrapTools.__elaborate.coreutils.onRun);

      writeTextFile = import ./write-text-file.nix;
      writeText = import ./write-text.nix;
      runCommand = import ./run-command.nix;
    }
  )

  # Setup first cc wrapper, binutils, grep and coreutils, ...
  (
    prevStage: {
      bash = inheritPackage (args: args.previous.bootstrapTools.__elaborate.bash.onRun);
      binutils = inheritPackage (args: args.previous.bootstrapTools.__elaborate.binutils.onRun);
      bzip2 = inheritPackage (args: args.previous.bootstrapTools.__elaborate.bzip2.onRun);
      coreutils = inheritPackage (args: args.previous.bootstrapTools.__elaborate.coreutils.onRun);
      diffutils = inheritPackage (args: args.previous.bootstrapTools.__elaborate.diffutils.onRun);
      findutils = inheritPackage (args: args.previous.bootstrapTools.__elaborate.findutils.onRun);
      gawk = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gawk.onRun);
      gcc-unwrapped = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gcc.onRun);
      gnugrep = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gnugrep.onRun);
      gnumake = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gnumake.onRun);
      gnupatch = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gnupatch.onRun);
      gnused = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gnused.onRun);
      gnutar = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gnutar.onRun);
      gzip = inheritPackage (args: args.previous.bootstrapTools.__elaborate.gzip.onRun);
    }
  )
]

# {
#   packages = {
#     bootstrapFiles = import ./bootstrap-files;
#
#     boot-bash = import ./bootstrap-tools/bash.nix;
#     bootstrapTools = import ./bootstrap-tools;
#     runCommand = import ./run-command.nix;
#
#     python = import ./python.nix;
#     m4 = import ./m4.nix;
#     bison = import ./bison.nix;
#     binutils = import ./binutils.nix;
#     glibc-boot = import ./glibc-boot.nix;
#   };
#
#   dependencies = {
#     stage0 = import ../stage0-posix;
#   };
# }
