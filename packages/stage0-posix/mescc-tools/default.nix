# Ported from Nixpkgs by GrizzlT

core:
core.mkPackage {
  function = {
    platforms,
    mescc-tools-boot,
    mescc-tools-boot2,
    mescc-tools,
    m2libc,
    src,
    mkMinimalPackage,
    buildPlatform,
    hostPlatform,
    targetPlatform,
    ...
  }: let

    inherit (mescc-tools-boot.onBuild)
      M2
      blood-elf-0
      ;

    inherit (mescc-tools-boot2.onBuildForHost)
      kaem-unwrapped
      M1
      hex2
      ;

    baseAddress = platforms.baseAddress hostPlatform;
    m2libcArch = platforms.m2libcArch hostPlatform;

    endianFlag = {
      "aarch64-linux" = "--little-endian";
      "i686-linux" = "--little-endian";
      "x86_64-linux" = "--little-endian";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    bloodFlag = {
      "aarch64-linux" = "--64";
      "i686-linux" = " ";
      "x86_64-linux" = "--64";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    # We need a few tools from mescc-tools-extra to assemble the output folder
    buildMesccToolsExtraUtil =
      name:
      mkMinimalPackage.onHost {
        name = "mescc-tools-extra-${name}";
        version = "1.6.0";
        drv = {
          builder = kaem-unwrapped;
          args = [
            "--verbose"
            "--strict"
            "--file"
            (builtins.toFile "build-${name}.kaem" ''
              ''${M2} --architecture ${m2libcArch} \
                -f ''${m2libc}/sys/types.h \
                -f ''${m2libc}/stddef.h \
                -f ''${m2libc}/${m2libcArch}/linux/fcntl.c \
                -f ''${m2libc}/fcntl.c \
                -f ''${m2libc}/${m2libcArch}/linux/unistd.c \
                -f ''${m2libc}/${m2libcArch}/linux/sys/stat.c \
                -f ''${m2libc}/stdlib.c \
                -f ''${m2libc}/stdio.h \
                -f ''${m2libc}/stdio.c \
                -f ''${m2libc}/string.c \
                -f ''${m2libc}/bootstrappable.c \
                -f ''${src}/mescc-tools-extra/${name}.c \
                --debug \
                -o ${name}.M1

              ''${blood-elf-0} ${endianFlag} ${bloodFlag} -f ${name}.M1 -o ${name}-footer.M1

              ''${M1} --architecture ${m2libcArch} \
                ${endianFlag} \
                -f ''${m2libc}/${m2libcArch}/${m2libcArch}_defs.M1 \
                -f ''${m2libc}/${m2libcArch}/libc-full.M1 \
                -f ${name}.M1 \
                -f ${name}-footer.M1 \
                -o ${name}.hex2

              ''${hex2} --architecture ${m2libcArch} \
                ${endianFlag} \
                -f ''${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2 \
                -f ${name}.hex2 \
                --base-address ${baseAddress} \
                -o ''${out}
            '')
          ];
          inherit
            M1
            M2
            blood-elf-0
            hex2
            m2libc
            src
            ;
        };
      };
    mkdir = buildMesccToolsExtraUtil "mkdir";
    cp = buildMesccToolsExtraUtil "cp";
    chmod = buildMesccToolsExtraUtil "chmod";
    replace = buildMesccToolsExtraUtil "replace";

  in mkMinimalPackage.onHost {
    name = "mescc-tools";
    version = "1.6.0";
    drv = {
      builder = kaem-unwrapped;
      args = [
        "--verbose"
        "--strict"
        "--file"
        ./build.kaem
      ];
      M1_host = mescc-tools-boot2.onHostForTarget.M1;
      hex2_host = mescc-tools-boot2.onHostForTarget.hex2;
      inherit
        M2
        M1
        blood-elf-0
        hex2

        m2libc
        src

        m2libcArch
        baseAddress
        bloodFlag
        endianFlag
        ;
    } // (if buildPlatform == hostPlatform then {
      inherit mkdir cp chmod replace;
    } else {
      inherit (mescc-tools.onBuildForHost) mkdir cp chmod replace;
    });
    public = {
      targetPlatform = hostPlatform;
      inherit mkdir cp chmod replace;
    };
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib.self) platforms;
    inherit (pkgs.self) mkMinimalPackage mescc-tools-boot mescc-tools-boot2 mescc-tools;
    src = pkgs.self.minimal-bootstrap-sources.onHost;
    m2libc = pkgs.self.minimal-bootstrap-sources.onHost.m2libc;
  };
}
