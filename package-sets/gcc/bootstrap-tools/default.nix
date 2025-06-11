{

  function = {
    bootstrapFiles,
    bash,
    runCommand,
    buildPlatform,
    runPlatform,
    ...
  }: let
    src = bootstrapFiles.onRun;
    linkerPrefix = {
      "x86_64-linux" = "ld-linux-x86-64.so.2";
    }.${runPlatform} or (throw "Unsupported platform: ${runPlatform}");
    linker = "${glibc}/lib/${linkerPrefix}";

    glibc = runCommand.onRun {
      name = "boot-glibc";
      buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${src}/glibc/lib/${linkerPrefix} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${src}/glibc/lib/${linkerPrefix} ${src}/coreutils/bin/cp -r ${src}/glibc/lib $out/
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${src}/glibc/lib/${linkerPrefix} ${src}/coreutils/bin/cp -r ${src}/glibc/include $out/
      '';
    };
    gmp = runCommand.onRun {
      name = "boot-gmp";
      buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/gmp/lib $out/
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/chmod -R u+w $out/lib
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          echo patching "$i"
          LD_LIBRARY_PATH=${glibc}/lib ${linker} ${src}/patchelf/bin/patchelf --set-rpath ${glibc}/lib --force-rpath "$i"
        done
      '';
    };
    patchelf = runCommand.onRun {
      name = "boot-patchelf";
      buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/patchelf/bin $out/
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/chmod u+w $out/bin/patchelf
        LD_LIBRARY_PATH=${glibc}/lib ${linker} ${src}/patchelf/bin/patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/patchelf
      '';
    };
    coreutils = runCommand.onRun {
      name = "boot-coreutils";
      tools = [ patchelf ];
      buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/coreutils/bin $out/
        LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/chmod u+w $out/bin/coreutils
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:${gmp}/lib --force-rpath $out/bin/coreutils
      '';
    };
    zlib = runCommand.onRun {
      name = "boot-zlib";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/zlib/lib $out
        chmod -R u+w $out
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib --force-rpath "$i"
        done
      '';
    };
    binutils = runCommand.onRun {
      name = "boot-binutils";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/binutils/bin $out
        cp -r ${src}/binutils/lib $out
        chmod -R u+w $out
        for i in $out/bin/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:${zlib}/lib --force-rpath "$i"
        done
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib:$out/lib:${zlib}/lib --force-rpath "$i"
        done
      '';
    };
    bzip2 = runCommand.onRun {
      name = "boot-bzip2";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/bzip2/bin $out
        cp -r ${src}/bzip2/lib $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:$out/lib --force-rpath $out/bin/bzip2
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib --force-rpath "$i"
        done
      '';
    };
    diffutils = runCommand.onRun {
      name = "boot-diffutils";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/diffutils/bin $out
        chmod -R u+w $out
        for i in $out/bin/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath "$i"
        done
      '';
    };
    findutils = runCommand.onRun {
      name = "boot-findutils";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/findutils/bin $out
        chmod -R u+w $out
        for i in $out/bin/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath "$i"
        done
      '';
    };
    gawk = runCommand.onRun {
      name = "boot-gawk";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gawk/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/gawk
      '';
    };
    pcre2 = runCommand.onRun {
      name = "boot-pcre2";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/pcre2/lib $out
        chmod -R u+w $out
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib:$out/lib --force-rpath "$i"
        done
      '';
    };
    bash' = runCommand.onRun {
      name = "boot-bash";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/bash/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/bash
        ln -s bash $out/bin/sh
      '';
    };
    gnugrep = runCommand.onRun {
      name = "boot-gnugrep";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gnugrep/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:${pcre2}/lib --force-rpath $out/bin/grep
        echo "#! ${bash.onRun}/bin/bash" > $out/bin/egrep
        echo "exec $out/bin/grep -E \"\$@\"" >> $out/bin/egrep
        echo "#! ${bash.onRun}/bin/bash" > $out/bin/fgrep
        echo "exec $out/bin/grep -F \"\$@\"" >> $out/bin/fgrep
        chmod +x $out/bin/egrep $out/bin/fgrep
      '';
    };
    gnumake = runCommand.onRun {
      name = "boot-gnumake";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gnumake/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/make
      '';
    };
    gnupatch = runCommand.onRun {
      name = "boot-gnupatch";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gnupatch/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/patch
      '';
    };
    gnused = runCommand.onRun {
      name = "boot-gnused";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gnused/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/sed
      '';
    };
    gnutar = runCommand.onRun {
      name = "boot-gnutar";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gnutar/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/tar
      '';
    };
    gzip = runCommand.onRun {
      name = "boot-gzip";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/gzip/bin $out
        chmod -R u+w $out
        patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/gzip
      '';
    };
    isl = runCommand.onRun {
      name = "boot-isl";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/isl/lib $out
        chmod -R u+w $out
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib:${gmp}/lib --force-rpath "$i" || true
        done
      '';
    };
    mpfr = runCommand.onRun {
      name = "boot-mpfr";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/mpfr/lib $out
        chmod -R u+w $out
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib:${gmp}/lib --force-rpath "$i"
        done
      '';
    };
    mpc = runCommand.onRun {
      name = "boot-mpc";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        mkdir -p $out
        cp -r ${src}/mpc/lib $out
        chmod -R u+w $out
        for i in $out/lib/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-rpath ${glibc}/lib:${gmp}/lib:${mpfr}/lib --force-rpath "$i"
        done
      '';
    };
    gcc = runCommand.onRun {
      name = "boot-gcc";
      tools = [ patchelf coreutils ];
      buildCommand = /* bash */ ''
        cp -r ${src}/gcc $out
        chmod -R u+w $out
        for i in $out/bin/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath "$i"
        done
        for i in $out/libexec/gcc/*/*/*; do
          if [ -L "$i" ]; then continue; fi
          patchelf --set-interpreter ${linker} \
            --set-rpath ${glibc}/lib:${isl}/lib:${mpc}/lib:${mpfr}/lib:${gmp}/lib:${zlib}/lib \
            --force-rpath "$i"
        done
        patchelf --set-rpath ${glibc}/lib --force-rpath $out/lib/libgcc_s.so.1
        patchelf --set-rpath ${glibc}/lib:$out/lib --force-rpath $out/lib/libstdc++*.so* || true
        cat <<EOF >$out/bin/gcc-wrapper
        #!${bash.onRun}/bin/bash
        set -eu -o pipefail +o posix

        if (( "\''${NIX_DEBUG:-0}" >= 7 )); then
            set -x
        fi

        NIX_RUNTIME_DEPS="\''${NIX_RUNTIME_DEPS:-${glibc}/lib}"
        NIX_CFLAGS_EXTRA="\''${NIX_CFLAGS_EXTRA:-}"

        $out/bin/gcc \\
          "\$@" \\
          -B${glibc}/lib \\
          -idirafter ${glibc}/include \\
          -Wl,--dynamic-linker,${glibc}/lib/${linkerPrefix} \\
          -Wl,-rpath,"\''${NIX_RUNTIME_DEPS}" \\
          -B$out/lib \\
          -B${binutils}/bin
        EOF
        chmod +x $out/bin/gcc-wrapper
      '';
    };


  in
    if buildPlatform != runPlatform then null
    else {
      __elaborate = "recursive";
      inherit
        binutils
        bzip2
        coreutils
        diffutils
        findutils
        gawk
        gcc
        gnugrep
        gnumake
        gnupatch
        gnused
        gnutar
        gzip
        patchelf
        ;
      bash = bash';
      inherit
        glibc
        gmp
        zlib
        pcre2
        isl
        mpfr
        mpc
        ;
      inherit buildPlatform runPlatform;
    };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) bootstrapFiles bash runCommand;
  };

}
