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

      mkMinimalPackage = import ./mk-minimal-package.nix;
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
      mkMinimalPackage = import ./mk-minimal-package.nix;
      runCommand = import ./run-command.nix;
    }
  )

  # Setup first cc wrapper, binutils, grep and coreutils, ...
  (
    prevStage: {
      bash = inheritPackage (args: args.previous.bootstrapTools.onRun.bash);
      binutils = inheritPackage (args: args.previous.bootstrapTools.onRun.binutils);
      bzip2 = inheritPackage (args: args.previous.bootstrapTools.onRun.bzip2);
      coreutils = inheritPackage (args: args.previous.bootstrapTools.onRun.coreutils);
      diffutils = inheritPackage (args: args.previous.bootstrapTools.onRun.diffutils);
      findutils = inheritPackage (args: args.previous.bootstrapTools.onRun.findutils);
      gawk = inheritPackage (args: args.previous.bootstrapTools.onRun.gawk);
      glibc = inheritPackage (args: args.previous.bootstrapTools.onRun.glibc);
      gcc-unwrapped = inheritPackage (args: args.previous.bootstrapTools.onRun.gcc);
      gnugrep = inheritPackage (args: args.previous.bootstrapTools.onRun.gnugrep);
      gnumake = inheritPackage (args: args.previous.bootstrapTools.onRun.gnumake);
      gnupatch = inheritPackage (args: args.previous.bootstrapTools.onRun.gnupatch);
      gnused = inheritPackage (args: args.previous.bootstrapTools.onRun.gnused);
      gnutar = inheritPackage (args: args.previous.bootstrapTools.onRun.gnutar);
      gzip = inheritPackage (args: args.previous.bootstrapTools.onRun.gzip);
    }
  )

  #
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
