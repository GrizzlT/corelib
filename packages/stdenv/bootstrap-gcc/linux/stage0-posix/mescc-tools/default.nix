{
  kaem-unwrapped,
  M1,
  M2,
  blood-elf-0,
  hex2,
  m2libc,
  src,
  version,
  ...
}:

let
  baseAddress = "0x00600000";
  m2libcArch = "amd64";

  endianFlag = "--little-endian";
  bloodFlag = "--64";

  # We need a few tools from mescc-tools-extra to assemble the output folder
  buildMesccToolsExtraUtil =
    name:
    derivation {
      name = "mescc-tools-extra-${name}-${version}";
      builder = kaem-unwrapped;
      system = "x86_64-linux";
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
  mkdir = buildMesccToolsExtraUtil "mkdir";
  cp = buildMesccToolsExtraUtil "cp";
  chmod = buildMesccToolsExtraUtil "chmod";
  replace = buildMesccToolsExtraUtil "replace";
in
derivation {
  name = "mescc-tools-${version}";
  builder = kaem-unwrapped;
  system = "x86_64-linux";
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];
  inherit
    M1
    M2
    blood-elf-0
    hex2
    mkdir
    cp
    chmod
    replace
    m2libc
    src
    m2libcArch
    baseAddress
    bloodFlag
    endianFlag
    ;
}
