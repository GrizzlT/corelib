core:
core.mkPackage {
  function = {
    std,
    fetchurl,
    kaem,
    runCommand,
    writeText,
    mescc-tools,
    mescc-tools-extra,
    mkMinimalPackage,
    hostPlatform,
    autoCall,
    ...
  }: let
    config_h = version: builtins.toFile "config.h" ''
      #undef SYSTEM_LIBC
      #define MES_VERSION "${version}"
    '';

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

    srcFn = version: fetchurl {
      url = "https://ftpmirror.gnu.org/mes//mes-${version}.tar.gz";
      hash = "sha256-MlJQs1Z+2SA7pwFhyDWvAQeec+vtl7S1u3fKUAuCiUA=";
    };

    nyacc = autoCall (import ./nyacc.nix) {};

    srcPost = name: version: let
      src = srcFn version;
    in runCommand.onHostForTarget "${name}-src-${version}" {
      inherit cc_cpu mes_cpu stage0_cpu blood_elf_flag;
      outputs = [
        "out"
        "bin"
      ];
    }
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
  in
    srcPost "mes" "0.25";
    # mkMinimalPackage.onHost {
    #   name = "mes";
    #   version = "0.25";
    #   drv = self: {
    #     builder = "${kaem.onBuild}/bin/kaem";
    #     args = [
    #       "--verbose"
    #       "--strict"
    #       "--file"
    #       # TODO: unpack source
    #       "\${src}/kaem.run"
    #     ];
    #     PATH = makeBinPath [
    #       kaem.onBuild
    #       mescc-tools.onBuildForHost
    #       mescc-tools-extra.onBuild
    #     ];
    #   };
    # };

  # mkMinimalPackage {
  #   name = "mes";
  #   version = "0.0.0";
  #   drv = self: {
  #     builder = "${kaem.onBuild}/bin/kaem";
  #     args = [
  #       "--verbose"
  #       "--strict"
  #       "--file"
  #       (writeText "mes-builder" buildCommand);
  #     ];
  #     PATH = std.strings.makeBinPath (
  #       [
  #         kaem.onBuild
  #         mescc-tools.onBuildForHost
  #         mescc-tools-extra.onBuild
  #       ]
  #     );
  #   };
  # };

  dep-defaults = { pkgs, lib, autoCall, ... }: {
    inherit autoCall;
    inherit (lib) std;
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

  # srcPost =
  #   kaem.runCommand "${pname}-src-${version}"
  #     {
  #       outputs = [
  #         "out"
  #         "bin"
  #       ];
  #       inherit meta;
  #     }
  #     ''
  #       # Unpack source
  #       ungz --file ${src} --output mes.tar
  #       mkdir ''${out}
  #       cd ''${out}
  #       untar --non-strict --file ''${NIX_BUILD_TOP}/mes.tar # ignore symlinks
  #
  #       MES_PREFIX=''${out}/mes-${version}
  #
  #       cd ''${MES_PREFIX}
  #
  #       cp ${config_h} include/mes/config.h
  #
  #       mkdir include/arch
  #       cp include/linux/x86/syscall.h include/arch/syscall.h
  #       cp include/linux/x86/kernel-stat.h include/arch/kernel-stat.h
  #
  #       # Remove pregenerated files
  #       rm mes/module/mes/psyntax.pp mes/module/mes/psyntax.pp.header
  #
  #       # These files are symlinked in the repo
  #       cp mes/module/srfi/srfi-9-struct.mes mes/module/srfi/srfi-9.mes
  #       cp mes/module/srfi/srfi-9/gnu-struct.mes mes/module/srfi/srfi-9/gnu.mes
  #
  #       # Remove environment impurities
  #       __GUILE_LOAD_PATH="\"''${MES_PREFIX}/mes/module:''${MES_PREFIX}/module:${nyacc.guilePath}\""
  #       boot0_scm=mes/module/mes/boot-0.scm
  #       guile_mes=mes/module/mes/guile.mes
  #       replace --file ''${boot0_scm} --output ''${boot0_scm} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}
  #       replace --file ''${guile_mes} --output ''${guile_mes} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}
  #
  #       module_mescc_scm=module/mescc/mescc.scm
  #       replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"M1\")" --replace-with "\"${mescc-tools}/bin/M1\""
  #       replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"HEX2\")" --replace-with "\"${mescc-tools}/bin/hex2\""
  #       replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"BLOOD_ELF\")" --replace-with "\"${mescc-tools}/bin/blood-elf\""
  #       replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"srcdest\")" --replace-with "\"''${MES_PREFIX}\""
  #
  #       mes_c=src/mes.c
  #       replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
  #       replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"srcdest\")" --replace-with "\"''${MES_PREFIX}\""
  #
  #       # Increase runtime resource limits
  #       gc_c=src/gc.c
  #       replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_ARENA\")" --replace-with "\"100000000\""
  #       replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_MAX_ARENA\")" --replace-with "\"100000000\""
  #       replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_STACK\")" --replace-with "\"6000000\""
  #
  #       # Create mescc.scm
  #       mescc_in=scripts/mescc.scm.in
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"includedir\")" --replace-with "\"''${MES_PREFIX}/include\""
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"libdir\")" --replace-with "\"''${MES_PREFIX}/lib\""
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on @prefix@ --replace-with ''${MES_PREFIX}
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on @VERSION@ --replace-with ${version}
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_cpu@ --replace-with x86
  #       replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_kernel@ --replace-with linux
  #       mkdir -p ''${bin}/bin
  #       cp ''${mescc_in} ''${bin}/bin/mescc.scm
  #
  #       # Build mes-m2
  #       kaem --verbose --strict --file kaem.x86
  #       cp bin/mes-m2 ''${bin}/bin/mes-m2
  #       chmod 555 ''${bin}/bin/mes-m2
  #     '';

