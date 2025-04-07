core:
core.mkPackage {
  function = {
    std,
    fetchurl,
    kaem,
    runCommand,
    writeText,
    mes,
    mescc-tools,
    mescc-tools-extra,
    mkMinimalPackage,
    buildPlatform,
    hostPlatform,
    autoCall,
    ...
  }: let
    inherit (std.lists) optionals;
    inherit (std.attrsets) optionalAttrs;
    inherit (std.strings) replaceStrings concatMapStringsSep;

    #####################
    #### Define cpu flags
    #
    # Fix: only x86 32-bit works currently

    cc_cpu = {
      "i686-linux" = "i386";
      # "x86_64-linux" = "x86_64";
      "x86_64-linux" = "i386";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    stage0_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86";
      # "x86_64-linux" = "amd64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    mes_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86";
      # "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    blood_elf_flag = {
      "i686-linux" = "";
      "x86_64-linux" = "";
      # "x86_64-linux" = "--64";
      "riscv64-linux" = "--64";
      "riscv32-linux" = "";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    ###################
    #### Define sources

    name = "mes";
    version = "0.25";
    src = fetchurl {
      url = "https://ftpmirror.gnu.org/mes//mes-${version}.tar.gz";
      hash = "sha256-MlJQs1Z+2SA7pwFhyDWvAQeec+vtl7S1u3fKUAuCiUA=";
    };

    nyacc = autoCall (import ./nyacc.nix) {};
    config_h = version: builtins.toFile "config.h" ''
      #undef SYSTEM_LIBC
      #define MES_VERSION "${version}"
    '';
    sources = (import ./new-sources.nix).${mes_cpu}.linux.mescc;
    # add symlink() to libc+tcc so we can use it in ln-boot
    libc_tcc_SOURCES = sources.libc_tcc_SOURCES ++ [ "lib/linux/symlink.c" ];

    srcPost = runCommand.onHost "${name}-src-${version}" ({
      inherit cc_cpu mes_cpu stage0_cpu;
      outputs = [
        "out"
        "bin"
      ];
    } // (optionalAttrs (blood_elf_flag != "") { inherit blood_elf_flag; }))
    # NOTE: hardcoded linux os
    /* bash */ ''
      ungz --file ${src} --output mes.tar
      mkdir ''${out}
      cd ''${out}
      untar --non-strict --file ''${NIX_BUILD_TOP}/mes.tar # ignore symlinks

      MES_PREFIX=''${out}/mes-${version}

      cd ''${MES_PREFIX}

      cp ${config_h version} include/mes/config.h
      mkdir -p include/arch
      cp include/linux/${mes_cpu}/kernel-stat.h include/arch
      cp include/linux/${mes_cpu}/syscall.h include/arch

      # Remove pregenerated files
      rm mes/module/mes/psyntax.pp mes/module/mes/psyntax.pp.header

      # These files are symlinked in the repo
      cp mes/module/srfi/srfi-9-struct.mes mes/module/srfi/srfi-9.mes
      cp mes/module/srfi/srfi-9/gnu-struct.mes mes/module/srfi/srfi-9/gnu.mes

      # Remove environment impurities
      __GUILE_LOAD_PATH="\"''${MES_PREFIX}/mes/module:''${MES_PREFIX}/module:${nyacc.guilePath}\""
      boot0_scm=mes/module/mes/boot-0.scm
      guile_mes=mes/module/mes/guile.mes
      replace --file ''${boot0_scm} --output ''${boot0_scm} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}
      replace --file ''${guile_mes} --output ''${guile_mes} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}

      module_mescc_scm=module/mescc/mescc.scm
      replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"M1\")" --replace-with "\"${mescc-tools.onHost}/bin/M1\""
      replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"HEX2\")" --replace-with "\"${mescc-tools.onHost}/bin/hex2\""
      replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"BLOOD_ELF\")" --replace-with "\"${mescc-tools.onHost}/bin/blood-elf\""
      replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"srcdest\")" --replace-with "\"''${MES_PREFIX}\""

      mes_c=src/mes.c
      replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
      replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"srcdest\")" --replace-with "\"''${MES_PREFIX}\""

      # Increase runtime resource limits
      gc_c=src/gc.c
      replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_ARENA\")" --replace-with "\"100000000\""
      replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_MAX_ARENA\")" --replace-with "\"100000000\""
      replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_STACK\")" --replace-with "\"6000000\""

      # Create mescc.scm
      mescc_in=scripts/mescc.scm.in
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"includedir\")" --replace-with "\"''${MES_PREFIX}/include\""
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"libdir\")" --replace-with "\"''${MES_PREFIX}/lib\""
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on @prefix@ --replace-with ''${MES_PREFIX}
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on @VERSION@ --replace-with ${version}
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_cpu@ --replace-with ${mes_cpu}
      replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_kernel@ --replace-with linux
      mkdir -p ''${bin}/bin
      cp ''${mescc_in} ''${bin}/bin/mescc.scm

      # Build mes-m2
      kaem --verbose --strict --file ${./build.kaem}
      cp bin/mes-m2 ''${bin}/bin/mes-m2
      chmod 555 ''${bin}/bin/mes-m2
    '';

    ##################
    #### Build GNU Mes

    srcPrefix = "${mes.onBuild.srcPost.out}/mes-${version}";
    cc = "${mes.onBuild.srcPost.bin}/bin/mes-m2";
    ccArgs = [
      "-e"
      "main"
      "${mes.onBuild.srcPost.bin}/bin/mescc.scm"
      "--"
      "-D"
      "HAVE_CONFIG_H=1"
      "-I"
      "${srcPrefix}/include"
      "-I"
      "${srcPrefix}/include/linux/${mes_cpu}"
      # "--arch=${mes_cpu}"
      # "--kernel=linux"
    ];# ++ (optionals (blood_elf_flag != "") ["-m" "64"]);

    CC = toString ([ cc ] ++ ccArgs);

    stripExt = source: replaceStrings [ ".c" ] [ "" ] (builtins.baseNameOf source);

    compile = source:
      runCommand.onHost (stripExt source) { } ''
        mkdir ''${out}
        cd ''${out}
        ${CC} -c ${srcPrefix}/${source}
      '';

    crt1 = compile "/lib/linux/${mes_cpu}-mes-mescc/crt1.c";
    getRes = suffix: res: "${res}/${res.name}${suffix}";

    archive = out: sources: "catm ${out} ${concatMapStringsSep " " (getRes ".o") sources}";
    sourceArchive = out: sources: "catm ${out} ${concatMapStringsSep " " (getRes ".s") sources}";

    mkLib = libname: sources: let
      os = map compile sources;
    in runCommand.onHost "${name}-${libname}-${version}" {}
        /* bash */ ''
          LIBDIR=''${out}/lib
          mkdir -p ''${LIBDIR}
          cd ''${LIBDIR}

          ${archive "${libname}.a" os}
          ${sourceArchive "${libname}.s" os}
        '';

    libc-mini = mkLib "libc-mini" sources.libc_mini_SOURCES;
    libmescc = mkLib "libmescc" sources.libmescc_SOURCES;
    libc = mkLib "libc" sources.libc_SOURCES;
    libc_tcc = mkLib "libc+tcc" libc_tcc_SOURCES;

    # Recompile Mes and Mes C library using mes-m2 bootstrapped Mes
    libs = runCommand.onHost "${name}-m2-libs-${version}" {}
      /* bash */ ''
        LIBDIR=''${out}/lib
        mkdir -p ''${out} ''${LIBDIR}

        mkdir -p ''${LIBDIR}/${mes_cpu}-mes

        # crt1.o
        cp ${crt1}/crt1.o ''${LIBDIR}/${mes_cpu}-mes
        cp ${crt1}/crt1.s ''${LIBDIR}/${mes_cpu}-mes

        # libc-mini.a
        cp ${libc-mini}/lib/libc-mini.a ''${LIBDIR}/${mes_cpu}-mes
        cp ${libc-mini}/lib/libc-mini.s ''${LIBDIR}/${mes_cpu}-mes

        # libmescc.a
        cp ${libmescc}/lib/libmescc.a ''${LIBDIR}/${mes_cpu}-mes
        cp ${libmescc}/lib/libmescc.s ''${LIBDIR}/${mes_cpu}-mes

        # libc.a
        cp ${libc}/lib/libc.a ''${LIBDIR}/${mes_cpu}-mes
        cp ${libc}/lib/libc.s ''${LIBDIR}/${mes_cpu}-mes

        # libc+tcc.a
        cp ${libc_tcc}/lib/libc+tcc.a ''${LIBDIR}/${mes_cpu}-mes
        cp ${libc_tcc}/lib/libc+tcc.s ''${LIBDIR}/${mes_cpu}-mes
      '';

    # Build mes itself
    compiler = runCommand.onHost "${name}-${version}"
      {
        public = {
          inherit src srcPost libs;
        };
      }
      ''
        mkdir -p ''${out}/bin

        ${mes.onBuild.srcPost.bin}/bin/mes-m2 -e main ${mes.onBuild.srcPost.bin}/bin/mescc.scm -- \
          -L ''${srcPrefix}/lib \
          -L ${libs}/lib \
          -lc \
          -lmescc \
          -nostdlib \
          -o ''${out}/bin/mes \
          ${libs}/lib/${mes_cpu}-mes/crt1.o \
          ${concatMapStringsSep " " (getRes ".o") (map compile sources.mes_SOURCES)}
      '';

  in
    if buildPlatform == hostPlatform
    then compiler
    else null;

  dep-defaults = { pkgs, lib, autoCall, ... }: {
    inherit autoCall;
    inherit (lib) std;
    inherit (pkgs.self) mes;
    inherit (pkgs.stage0)
      kaem
      mkMinimalPackage
      runCommand
      writeText
      mescc-tools
      mescc-tools-extra
      ;
    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}
