{ bootstrapTools, fetchurl, ... }:
let
  tccSrc = fetchurl {
    name = "tinycc-src.tar.gz";
    url = "https://github.com/TinyCC/tinycc/archive/f8bd136d198bdafe71342517fa325da2e243dc68.tar.gz";
    hash = "sha256-oji53+lbYMdDRFbSdKdNB1ne3mY9xOsmwLSLi2WIY7o=";
  };
  muslSrc = fetchurl {
    name = "musl-1.2.5";
    url = "https://musl.libc.org/releases/musl-1.2.5.tar.gz";
    hash = "sha256-qaEYu+hNh2TaDqDSizqz+uhHf8fkCF2QECuFlvx8deQ=";
  };

  musl = derivation {
    name = "musl-1.2.5_stage1";
    system = "x86_64-linux";
    builder = "${bootstrapTools}/bin/bash";
    inherit muslSrc bootstrapTools;
    args = ["-e" (builtins.toFile "script" /* bash */ ''
      PATH=$bootstrapTools/bin
      gzip -dc <$muslSrc | tar x --strip-components 1

      ln -sT $bootstrapTools/bin/tinycc $NIX_BUILD_TOP/ld

      echo "#! $bootstrapTools/bin/sh" > $NIX_BUILD_TOP/cc-wrapper
      echo "exec $bootstrapTools/bin/gcc -B$NIX_BUILD_TOP -nostdinc -nostdlib \"\$@\"" >> $NIX_BUILD_TOP/cc-wrapper
      chmod +x cc-wrapper

      export CC=$NIX_BUILD_TOP/cc-wrapper
      ./configure --prefix=$out --disable-shared
      make
      make install
    '')];
    allowedRequisites = [];
  };
in {
  # tcc = tcc0;
  musl = musl;
  inherit tccSrc muslSrc;
}
