lib:
{
  function = {
    fetchurl,
    runCommand,
    m2libc,
    buildPlatform,
    runPlatform,
    ...
  }: let

    #####################
    #### Define cpu flags

    cc_cpu = {
      "i686-linux" = "i386";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${runPlatform} or (throw "Unsupported system: ${runPlatform}");

    stage0_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "amd64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${runPlatform} or (throw "Unsupported system: ${runPlatform}");

    mes_cpu = {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${runPlatform} or (throw "Unsupported system: ${runPlatform}");

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

    srcPost = runCommand.onRun {
      inherit version;
      name = "${name}-src";
      env = {
        inherit cc_cpu mes_cpu stage0_cpu m2libc;
        outputs = [
          "out" "bin"
        ];
        buildCommand = /* bash */ ''
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

          mkdir -p ''${bin}/bin

          kaem --verbose --strict --file ${./build.kaem}
          cp bin/mes ''${bin}/bin/mes
          chmod 555 ''${bin}/bin/mes
        '';
      };
    };

    srcPrefix = "${srcPost.out}/mes-${version}";

  in {
    inherit src srcPost srcPrefix;
    inherit buildPlatform runPlatform;
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.stage0.minimal-bootstrap-sources) m2libc;
    inherit (pkgs.stage0)
      runCommand
      fetchurl
      ;
  };
}
