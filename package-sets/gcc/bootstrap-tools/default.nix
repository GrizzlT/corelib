{

  function = {
    bootstrapFiles,
    boot-bash,
    runCommand,
    buildPlatform,
    runPlatform,
    ...
  }: let
    src = bootstrapFiles.onRun;
    linker = {
      "x86_64-linux" = "${src}/glibc/lib/ld-linux-x86-64.so.2";
    }.${runPlatform} or (throw "Unsupported platform: ${runPlatform}");

    glibc = runCommand.onRun {
      name = "boot-glibc";
      env.buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/glibc/lib $out/
        LD_LIBRARY_PATH=${src}/glibc/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/glibc/include $out/
      '';
    };
    gmp = runCommand.onRun {
      name = "boot-gmp";
      env.buildCommand = /* bash */ ''
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
      env.buildCommand = /* bash */ ''
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/mkdir $out
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/patchelf/bin $out/
        LD_LIBRARY_PATH=${glibc}/lib:${src}/gmp/lib ${linker} ${src}/coreutils/bin/chmod u+w $out/bin/patchelf
        LD_LIBRARY_PATH=${glibc}/lib ${linker} ${src}/patchelf/bin/patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/patchelf
      '';
    };
    coreutils = runCommand.onRun {
      name = "boot-coreutils";
      env = {
        tools = [ patchelf ];
        buildCommand = /* bash */ ''
          LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/mkdir $out
          LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/cp -r ${src}/coreutils/bin $out/
          LD_LIBRARY_PATH=${glibc}/lib:${gmp}/lib ${linker} ${src}/coreutils/bin/chmod u+w $out/bin/coreutils
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:${gmp}/lib --force-rpath $out/bin/coreutils
        '';
      };
    };
    zlib = runCommand.onRun {
      name = "boot-zlib";
      env = {
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
    };
    binutils = runCommand.onRun {
      name = "boot-binutils";
      env = {
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
    };
    bzip2 = runCommand.onRun {
      name = "boot-bzip2";
      env = {
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
    };
    diffutils = runCommand.onRun {
      name = "boot-diffutils";
      env = {
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
    };
    findutils = runCommand.onRun {
      name = "boot-findutils";
      env = {
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
    };
    gawk = runCommand.onRun {
      name = "boot-gawk";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gawk/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/gawk
        '';
      };
    };
    pcre2 = runCommand.onRun {
      name = "boot-pcre2";
      env = {
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
    };
    gnugrep = runCommand.onRun {
      name = "boot-gnugrep";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gnugrep/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib:${pcre2}/lib --force-rpath $out/bin/grep
          echo "#! ${boot-bash.onRun}/bin/bash" > $out/bin/egrep
          echo "exec $out/bin/grep -E \"\$@\"" >> $out/bin/egrep
          echo "#! ${boot-bash.onRun}/bin/bash" > $out/bin/fgrep
          echo "exec $out/bin/grep -F \"\$@\"" >> $out/bin/fgrep
          chmod +x $out/bin/egrep $out/bin/fgrep
        '';
      };
    };
    gnumake = runCommand.onRun {
      name = "boot-gnumake";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gnumake/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/make
        '';
      };
    };
    gnupatch = runCommand.onRun {
      name = "boot-gnupatch";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gnupatch/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/patch
        '';
      };
    };
    gnused = runCommand.onRun {
      name = "boot-gnused";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gnused/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/sed
        '';
      };
    };
    gnutar = runCommand.onRun {
      name = "boot-gnutar";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gnutar/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/tar
        '';
      };
    };
    gzip = runCommand.onRun {
      name = "boot-gzip";
      env = {
        tools = [ patchelf coreutils ];
        buildCommand = /* bash */ ''
          mkdir -p $out
          cp -r ${src}/gzip/bin $out
          chmod -R u+w $out
          patchelf --set-interpreter ${linker} --set-rpath ${glibc}/lib --force-rpath $out/bin/gzip
        '';
      };
    };
    isl = runCommand.onRun {
      name = "boot-isl";
      env = {
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
    };
    mpfr = runCommand.onRun {
      name = "boot-mpfr";
      env = {
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
    };
    mpc = runCommand.onRun {
      name = "boot-mpc";
      env = {
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
    };
    gcc = runCommand.onRun {
      name = "boot-gcc";
      env = {
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
        '';
      };
    };


  in
    if buildPlatform != runPlatform then null
    else {
      inherit
        coreutils
        patchelf
        binutils
        bzip2
        diffutils
        findutils
        gawk
        gnugrep
        gnumake
        gnupatch
        gnused
        gnutar
        gzip
        gcc
        ;
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
    inherit (pkgs.self) bootstrapFiles boot-bash runCommand;
  };

}
