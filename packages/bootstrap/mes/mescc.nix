core:
core.mkPackage {
  function = {
    std,
    platforms,
    fetchurl,
    runCommand,
    hostPlatform,
    ...
  }: let

    mes_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    #############
    #### Define sources
    name = "mes";
    version = "0.27";
    src = fetchurl {
      url = "https://ftpmirror.gnu.org/mes//mes-${version}.tar.gz";
      hash = "sha256-Az7mVtmM/ASoJuqyfu1uaidtFbu5gKfNcdAPMCJ6qqg=";
    };

    config_h = builtins.toFile "config.h" ''
      #undef SYSTEM_LIBC
      #define MES_VERSION "${version}"
    '';

    srcPost = runCommand.onHost {
      inherit version;
      name = "${name}-src";
      env.buildCommand = /* bash */ ''
        ungz --file ${src} --output mes.tar
        mkdir ''${out}
        cd ''${out}
        untar --non-strict --file ''${NIX_BUILD_TOP}/mes.tar # ignore symlinks

        MES_PREFIX="''${out}/mes-${version}"
        cd ''${MES_PREFIX}

        cp ${config_h} include/mes/config.h
        mkdir -p include/arch
        cp include/linux/${mes_cpu}/kernel-stat.h include/arch
        cp include/linux/${mes_cpu}/signal.h include/arch
        cp include/linux/${mes_cpu}/syscall.h include/arch

        # These files are symlinked in the repo
        cp mes/module/srfi/srfi-9-struct.mes mes/module/srfi/srfi-9.mes
        cp mes/module/srfi/srfi-9/gnu-struct.mes mes/module/srfi/srfi-9/gnu.mes


      '';
    };

  in srcPost;

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (lib.stage0) platforms;
    inherit (pkgs.stage0)
      runCommand
      fetchurl
      ;
  };
}
