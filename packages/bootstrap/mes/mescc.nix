core:
core.mkPackage {
  function = {
    std,
    platforms,
    fetchurl,
    mes,
    runCommand,
    buildPlatform,
    hostPlatform,
    ...
  }: let
    inherit (std.strings) replaceStrings concatMapStringsSep;
    inherit (mes.onHost) srcPrefix;

    #####################
    #### Define cpu flags

    cc_cpu = {
      "i686-linux" = "i386";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    stage0_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "amd64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    mes_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    blood_elf_flag = {
      "i686-linux" = "";
      "x86_64-linux" = "--64";
      "riscv64-linux" = "--64";
      "riscv32-linux" = "";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    baseAddress = platforms.baseAddress hostPlatform;

    #############
    #### Define sources
    name = "mescc";
    version = "0.27";

    stripExt = source: replaceStrings [ ".c" ] [ "" ] (builtins.baseNameOf source);

    compile = source: runCommand.onHost {
      name = stripExt source;
      env = {
        MES_ARENA = 20000000;
        MES_MAX_ARENA = 20000000;
        MES_STACK = 6000000;
        MES_PREFIX = "${srcPrefix}";

        # GUILE_LOAD_PATH = "$abs_top_srcdir/module:$abs_top_srcdir/mes:$abs_top_srcdir/guix${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH";
        GUILE_LOAD_PATH = "${srcPrefix}/mes/module:${srcPrefix}/module";
        includedir = "${srcPrefix}/include";
        libdir = "${srcPrefix}/lib";

        buildCommand = /* bash */ ''
          mkdir ''${out}
          cd ''${out}
          echo ''${GUILE_LOAD_PATH}

          # compile source
          ${mes.onBuild.srcPost.bin}/bin/mes \
            --no-auto-compile \
            -e main \
            -L "" \
            -C "" \
            ${srcPrefix}/module/mescc.scm \
            --help
        '';
      };
    };

  in compile "/lib/linux/${mes_cpu}-mes-mescc/crt1.c";

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (lib.stage0) platforms;
    inherit (pkgs.stage0)
      kaem
      runCommand
      fetchurl
      writeTextFile
      ;
    inherit (pkgs.self)
      mes
      ;
  };
}
