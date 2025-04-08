core:
core.mkPackage {
  function = {
    std,
    mes-arch,
    runCommand,
    ln-boot,
    mes,
    mes-libc,
    buildPlatform,
    hostPlatform,
    ...
  }: let

    inherit (std.strings) concatStringsSep;

    mes_cpu = mes-arch.mes_cpu hostPlatform;

    sources = (import ./sources.nix).${mes_cpu}.linux.gcc;
    inherit (sources) libtcc1_SOURCES libc_gnu_SOURCES;

    # Concatenate all source files into a convenient bundle
    # "gcc" variants of source files (eg. "lib/linux/x86-mes-gcc") can also be
    # compiled by tinycc
    #
    # Passing this many arguments is too much for kaem so we need to split
    # the operation in two
    firstLibc = std.lists.take 100 libc_gnu_SOURCES;
    lastLibc = std.lists.drop 100 libc_gnu_SOURCES;

  in
    if buildPlatform == hostPlatform
    then runCommand.onHost "mes-libc"
      {
        tools = [ ln-boot.onBuild ];

        public.CFLAGS = "-DHAVE_CONFIG_H=1 -I${mes-libc.onHost}/include -I${mes-libc.onHost}/include/linux/${mes_cpu}";
      }
      ''
        cd ${mes.onHost.srcPrefix}

        # mescc compiled libc.a
        mkdir -p ''${out}/lib/${mes_cpu}-mes

        # libc.c
        catm ''${TMPDIR}/first.c ${concatStringsSep " " firstLibc}
        catm ''${out}/lib/libc.c ''${TMPDIR}/first.c ${concatStringsSep " " lastLibc}

        # crt{1,n,i}.c
        cp lib/linux/${mes_cpu}-mes-gcc/crt1.c ''${out}/lib
        cp lib/linux/${mes_cpu}-mes-gcc/crtn.c ''${out}/lib
        cp lib/linux/${mes_cpu}-mes-gcc/crti.c ''${out}/lib

        # libtcc1.c
        catm ''${out}/lib/libtcc1.c ${concatStringsSep " " libtcc1_SOURCES}

        # getopt.c
        cp lib/posix/getopt.c ''${out}/lib/libgetopt.c

        # Install headers
        ln -s ${mes.onHost.srcPrefix}/include ''${out}/include
      ''
    else null;

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (lib.self) mes-arch;
    inherit (pkgs.self) ln-boot mes mes-libc;
    inherit (pkgs.stage0) runCommand;
  };
}
