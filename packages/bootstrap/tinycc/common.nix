core:
core.mkPackage {
  function = {
    std,
    runCommand,
    mes-libc,
    tcc-arch,
    buildPlatform,
    hostPlatform,
    targetPlatform,
    ...
  }: let

    inherit (std.strings) concatStringsSep;

    tcc_target_arch = tcc-arch.tcc_target_arch hostPlatform;

    recompileLibc = {
      tcc,
      name,
      version,
      src,
      libtccOptions,
    }: let
      crt = runCommand.onHost "crt" { } ''
        mkdir -p ''${out}/lib
        ${tcc}/bin/tcc ${mes-libc.onHost.CFLAGS} -c -o ''${out}/lib/crt1.o ${mes-libc.onHost}/lib/crt1.c
        ${tcc}/bin/tcc ${mes-libc.onHost.CFLAGS} -c -o ''${out}/lib/crtn.o ${mes-libc.onHost}/lib/crtn.c
        ${tcc}/bin/tcc ${mes-libc.onHost.CFLAGS} -c -o ''${out}/lib/crti.o ${mes-libc.onHost}/lib/crti.c
      '';

      library =
        lib: options: source:
        runCommand.onHost "${lib}.a" { } ''
          ${tcc}/bin/tcc ${options} -c -o ${lib}.o ${source}
          ${tcc}/bin/tcc -ar cr ''${out} ${lib}.o
        '';

      libtcc1 = library "libtcc1" libtccOptions "${src}/lib/libtcc1.c";
      libc = library "libc" mes-libc.onHost.CFLAGS "${mes-libc.onHost}/lib/libc.c";
      libgetopt = library "libgetopt" mes-libc.onHost.CFLAGS "${mes-libc.onHost}/lib/libgetopt.c";
    in
      runCommand.onHost "${name}-libs-${version}" { } ''
        mkdir -p ''${out}/lib
        cp ${crt}/lib/crt1.o ''${out}/lib
        cp ${crt}/lib/crtn.o ''${out}/lib
        cp ${crt}/lib/crti.o ''${out}/lib
        cp ${libtcc1} ''${out}/lib/libtcc1.a
        cp ${libc} ''${out}/lib/libc.a
        cp ${libgetopt} ''${out}/lib/libgetopt.a
      '';

    buildTinyccMes =
      {
        name,
        version,
        src,
        prev,
        buildOptions,
        libtccBuildOptions,
      }:
      let
        options = concatStringsSep " " buildOptions;
        libtccOptions = concatStringsSep " " (
          [
            "-c"
            "-D"
            "TCC_TARGET_${tcc_target_arch}=1"
          ]
          ++ libtccBuildOptions
        );
        compiler =
          runCommand.onHost "${name}-${version}" {
            public = { inherit prev; };
          }
          ''
            catm config.h
            mkdir -p ''${out}/bin
            ${prev.compiler}/bin/tcc \
              -B ${prev.libs}/lib \
              -g \
              -v \
              -o ''${out}/bin/tcc \
              -D BOOTSTRAP=1 \
              ${options} \
              -I . \
              -I ${src} \
              -D TCC_TARGET_${tcc_target_arch}=1 \
              -D CONFIG_TCCDIR=\"\" \
              -D CONFIG_SYSROOT=\"\" \
              -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
              -D CONFIG_TCC_ELFINTERP=\"\" \
              -D CONFIG_TCC_LIBPATHS=\"{B}\" \
              -D CONFIG_TCC_SYSINCLUDEPATHS=\"${mes-libc.onHost}/include\" \
              -D TCC_LIBGCC=\"libc.a\" \
              -D TCC_LIBTCC1=\"libtcc1.a\" \
              -D CONFIG_TCCBOOT=1 \
              -D CONFIG_TCC_STATIC=1 \
              -D CONFIG_USE_LIBGCC=1 \
              -D TCC_MES_LIBC=1 \
              -D TCC_VERSION=\"${version}\" \
              -D ONE_SOURCE=1 \
              ${src}/tcc.c
          '';

        libs = recompileLibc {
          inherit
            name
            version
            src
            libtccOptions
            ;
          tcc = compiler;
        };
      in
      {
        inherit prev compiler libs;
      };

  in {
    inherit buildPlatform hostPlatform;

    inherit recompileLibc buildTinyccMes;
  };

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (lib.self) tcc-arch;
    inherit (pkgs.stage0) runCommand;
    inherit (pkgs.self) mes-libc;
  };
}
