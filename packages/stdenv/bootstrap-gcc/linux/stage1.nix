{ bootstrapTools, fetchurl, stage1, ... }:
let
  muslSrc = fetchurl {
    name = "musl-1.2.5";
    url = "https://musl.libc.org/releases/musl-1.2.5.tar.gz";
    hash = "sha256-qaEYu+hNh2TaDqDSizqz+uhHf8fkCF2QECuFlvx8deQ=";
  };

  binutilsSrc = fetchurl {
    name = "binutils-2.43.1";
    url = "https://ftpmirror.gnu.org/gnu/binutils/binutils-2.43.1.tar.gz";
    hash = "sha256-5MOLiT9ZCFP74namuKEmgQHjXmGEmgf27pe17Ml/v/g=";
  };

  musl = derivation {
    name = "musl-1.2.5_stage1";
    system = "x86_64-linux";
    builder = "${bootstrapTools}/bin/bash";
    inherit muslSrc bootstrapTools;
    args = ["-e" (builtins.toFile "script" /* bash */ ''
      PATH=$bootstrapTools/bin
      gzip -dc <$muslSrc | tar x --strip-components 1

      echo "#! $bootstrapTools/bin/sh" > $NIX_BUILD_TOP/cc-wrapper
      echo "exec $bootstrapTools/bin/gcc -nostdinc -nostdlib \"\$@\"" >> $NIX_BUILD_TOP/cc-wrapper
      chmod +x cc-wrapper

      export CC=$NIX_BUILD_TOP/cc-wrapper
      ./configure \
        CONFIG_SHELL="$bootstrapTools/bin/bash" \
        SHELL="$bootstrapTools/bin/bash" \
        --prefix=$out --disable-shared
      make
      make install
    '')];
    allowedRequisites = [];
  };

  binutils = derivation {
    name = "binutils-2.43.1_stage1";
    system = "x86_64-linux";
    builder = "${bootstrapTools}/bin/bash";
    inherit binutilsSrc bootstrapTools;
    musl = stage1.musl;
    args = ["-e" (builtins.toFile "script" /* bash */ ''
      PATH=$bootstrapTools/bin
      gzip -dc <$binutilsSrc | tar x --strip-components 1

      echo "#! $bootstrapTools/bin/sh" > $NIX_BUILD_TOP/cc-wrapper
      echo "exec $bootstrapTools/bin/gcc -nostdinc -nostdlib \"\$@\"" >> $NIX_BUILD_TOP/cc-wrapper
      echo "#! $bootstrapTools/bin/sh" > $NIX_BUILD_TOP/cpp-wrapper
      echo "exec $bootstrapTools/bin/gcc -nostdinc -nostdlib -E -I$musl/include \"\$@\"" >> $NIX_BUILD_TOP/cpp-wrapper

      # echo "#! $bootstrapTools/bin/sh" > $NIX_BUILD_TOP/ld-wrapper
      # echo "exec $bootstrapTools/bin/ld -L$musl/lib -lc \"\$@\"" >> $NIX_BUILD_TOP/ld-wrapper
      chmod +x cc-wrapper
      chmod +x cpp-wrapper

      export CC=$NIX_BUILD_TOP/cc-wrapper
      export CPP=$NIX_BUILD_TOP/cpp-wrapper
      export lt_cv_sys_max_cmd_len=32768
      export ac_cv_func_strncmp_works=no

      ./configure \
        CONFIG_SHELL="$bootstrapTools/bin/bash" \
        SHELL="$bootstrapTools/bin/bash" \
        --enable-deterministic-archives \
        --disable-gprofng --disable-nls \
        --prefix=$out --disable-shared --enable-static \
        --enable-new-dtags \
        --host=x86_64-linux --target=x86_64-linux \
        --program-prefix=x86_64-linux
      echo "reached end of configure"
      # build
      # make \
      #         all-libiberty all-gas all-bfd all-libctf all-zlib all-gprof
      make all-libiberty
      # make all-ld  # race condition on ld/.deps/ldwrite.Po, serialize
    '')];
    allowedRequisites = [];
  };
in {
  inherit musl binutils;
  inherit muslSrc binutilsSrc;
}
