lib:
{

  function = {
    bootstrapFiles,
    runCommand,
    kaem,
    mescc-tools-extra,
    buildPlatform,
    runPlatform,
    ...
  }: let
    src = bootstrapFiles.onRun;

    linker = {
      "x86_64-linux" = "${src}/glibc/lib/ld-linux-x86-64.so.2";
    }.${runPlatform} or (throw "Unsupported platform: ${runPlatform}");
  in
    if buildPlatform != runPlatform then null
    else runCommand.onRun {
      name = "bootstrap-bash";
      version = null;
      buildCommand = /* sh */ ''
        mkdir -p ''${out}/bin
        cp ''${src}/bash/bin/bash ''${out}/bin/bash

        ''${LD_BINARY} ''${src}/patchelf/bin/patchelf --set-interpreter ${linker} --set-rpath ''${src}/glibc/lib --force-rpath ''${out}/bin/bash
        chmod 555 ''${out}/bin/bash
      '';
      args = [
        "--verbose"
        "--strict"
        "--file"
        (builtins.toFile "kaem-build-command.sh" ''
          kaem --verbose --strict --file ''${buildCommandPath}
        '')
      ];
      shell = "${kaem.onBuild}/bin/kaem";
      tools = [
        kaem.onBuild
        mescc-tools-extra.onBuild
      ];
      env = {
        LD_LIBRARY_PATH = "${src}/glibc/lib";
        LD_BINARY = linker;
        inherit src;
        allowedReferences = [ src ];
      };
    };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) bootstrapFiles runCommand;
    inherit (pkgs.stage0) kaem mescc-tools-extra;
  };

}
