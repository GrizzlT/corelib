core:
core.mkPackage {
  function = {
    runCommand,
    mes,
    buildPlatform,
    hostPlatform,
    ...
  }:
    let
      src = ./ln.c;
    in
      if buildPlatform == hostPlatform then
        runCommand.onHost "ln-boot" {}
          ''
            mkdir -p ''${out}/bin
            ${mes.onBuild}/bin/mes --no-auto-compile -e main ${mes.onBuild.srcPost.bin}/bin/mescc.scm -- \
              -L ${mes.onBuild.libs}/lib \
              -lc+tcc \
              -o ''${out}/bin/ln \
              ${src}
          ''
      else null;

  dep-defaults = { lib, pkgs, ... }: {
    inherit (pkgs.self) mes;
    inherit (pkgs.stage0) runCommand;
  };
}
