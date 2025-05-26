lib:
{
  function = {
    fetchurl,
    mes,
    runCommand,

    deferCall,
    buildPlatform,
    runPlatform,
    ...
  }: let
    inherit (lib.std.strings) replaceStrings concatMapStringsSep;
    inherit (mes.onRun) srcPrefix; # onRun to get correct include flags for libc

    #####################
    #### Define cpu flags
    mes_cpu = lib.self.mes-arch.mes_cpu runPlatform;

    #############
    #### Define sources
    version = "0.27";
    mes-bootstrap = deferCall (import ./mes-boot.nix) {};
    nyacc = deferCall (import ./nyacc.nix) {};
    sources = (import ./sources.nix) { inherit mes_cpu; };

    stripExt = source: replaceStrings [ ".c" ] [ "" ] (builtins.baseNameOf source);

    mesBin = if buildPlatform == runPlatform then
      mes-bootstrap.srcPost.bin
    else mes.onBuild;

    compile = source: runCommand.onRun {
      name = stripExt source;
      env = {
        MES_ARENA = 20000000;
        MES_MAX_ARENA = 20000000;
        MES_STACK = 6000000;
        MES_PREFIX = "${srcPrefix}";

        GUILE_LOAD_PATH = "${srcPrefix}/mes/module:${srcPrefix}/module:${nyacc.guilePath}";

        buildCommand = /* bash */ ''
          mkdir ''${out}
          cd ''${out}

          # compile source
          ${mesBin}/bin/mes \
            --no-auto-compile \
            -e main \
            ${mes.onBuild.srcPrefix}/module/mescc.scm \
            -- \
            --arch ${mes_cpu} \
            -D HAVE_CONFIG_H=1 \
            -I ${srcPrefix}/include \
            -L ${srcPrefix}/lib \
            -c ${srcPrefix}/${source}
        '';
      };
    };

    crt1 = compile "/lib/linux/${mes_cpu}-mes-mescc/crt1.c";
    getRes = suffix: res: "${res}/${res.name}${suffix}";

    archive = out: sources: "catm ${out} ${concatMapStringsSep " " (getRes ".o") sources}";
    sourceArchive = out: sources: "catm ${out} ${concatMapStringsSep " " (getRes ".s") sources}";

    mkLib = libname: sources: let
      os = map compile sources;
    in runCommand.onRun {
      name = "mes-${libname}";
      inherit version;
      env.buildCommand = /* bash */ ''
        LIBDIR=''${out}/lib
        mkdir -p ''${LIBDIR}
        cd ''${LIBDIR}

        ${archive "${libname}.a" os}
        ${sourceArchive "${libname}.s" os}
      '';
    };

    libc-mini = mkLib "libc-mini" sources.libc-mini;
    libmescc = mkLib "libmescc" sources.libmescc;
    libc = mkLib "libc" sources.libc;
    libc_tcc = mkLib "libc+tcc" sources.libc_tcc;

    libs = runCommand.onRun {
      name = "mes-m2-libs";
      inherit version;
      env.buildCommand = /* bash */ ''
        LIBDIR=''${out}/lib
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
    };

  in runCommand.onRun {
    name = "mes";
    inherit version;

    env = {
      MES_ARENA = 20000000;
      MES_MAX_ARENA = 20000000;
      MES_STACK = 6000000;
      MES_PREFIX = "${srcPrefix}";

      GUILE_LOAD_PATH = "${srcPrefix}/mes/module:${srcPrefix}/module:${nyacc.guilePath}";

      buildCommand = /* bash */ ''
        mkdir -p ''${out}/bin

        # compile source
        ${mesBin}/bin/mes                           \
          --no-auto-compile                         \
          -e main                                   \
          ${mes.onBuild.srcPrefix}/module/mescc.scm \
          --                                        \
          --arch ${mes_cpu}                         \
          -L ${srcPrefix}/lib                       \
          -L ${libs}/lib                            \
          -lc                                       \
          -lmescc                                   \
          -nostdlib                                 \
          -o ''${out}/bin/mes                       \
          ${libs}/lib/${mes_cpu}-mes/crt1.o         \
          ${concatMapStringsSep " " (getRes ".o") (map compile sources.mes)}
      '';
    };

    public = {
      inherit (mes-bootstrap) src srcPost srcPrefix;
      inherit libs;
    };
  };

  inputs = { pkgs, deferCall, ... }: {
    inherit deferCall;
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
