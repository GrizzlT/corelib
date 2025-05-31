{

  function = {
    bootstrapFiles,
    boot-bash,
    runCommand,
    writeText,
    buildPlatform,
    runPlatform,
    ...
  }: let
    src = bootstrapFiles.onRun;
    name = "bootstrap-tools";
  in
    if buildPlatform != runPlatform then null
    else runCommand.onRun {
      inherit name;
      shell = "${boot-bash.onBuild}/bin/bash";
      env = {
        args = [
          (writeText "${name}-patchelf-all" /* bash */ ''
set -xeu
mkdir $out

# Set the ELF interpreter / RPATH in the bootstrap binaries.
echo Patching the bootstrap tools...

if test -f $src/lib/ld.so.?; then
   # MIPS case
   LD_BINARY=$src/lib/ld.so.?
elif test -f $src/lib/ld64.so.?; then
   # ppc64(le)
   LD_BINARY=$src/lib/ld64.so.?
else
   # i686, x86_64 and armv5tel
   LD_BINARY=$src/lib/ld-*so.?
fi
# path to version-specific libraries, like libstdc++.so
LIBSTDCXX_SO_DIR=$(echo $src/lib/gcc/*/*)

# Copy source
LD_LIBRARY_PATH=$src/lib $LD_BINARY $src/bin/cp -r $src/* $out/
LD_LIBRARY_PATH=$src/lib $LD_BINARY $src/bin/chmod -R 777 $out

if test -f $out/lib/ld.so.?; then
   # MIPS case
   LD_BINARY=$out/lib/ld.so.?
elif test -f $out/lib/ld64.so.?; then
   # ppc64(le)
   LD_BINARY=$out/lib/ld64.so.?
else
   # i686, x86_64 and armv5tel
   LD_BINARY=$out/lib/ld-*so.?
fi
# path to version-specific libraries, like libstdc++.so
LIBSTDCXX_SO_DIR=$(echo $out/lib/gcc/*/*)

# Move version-specific libraries out to avoid library mix when we
# upgrade gcc.
# TODO(trofi): update bootstrap tarball script and tarballs to put them
# into expected location directly.
LD_LIBRARY_PATH=$out/lib $LD_BINARY $out/bin/mv $out/lib/libstdc++.* $LIBSTDCXX_SO_DIR/

# On x86_64, ld-linux-x86-64.so.2 barfs on patchelf'ed programs.  So
# use a copy of patchelf.
LD_LIBRARY_PATH=$out/lib $LD_BINARY $out/bin/cp $out/bin/patchelf .

LD_LIBRARY_PATH=.:$out/lib:$LIBSTDCXX_SO_DIR $LD_BINARY \
  ./patchelf --set-rpath $out/lib --force-rpath $out/lib/libgcc_s.so.1

for i in $out/bin/* $out/libexec/gcc/*/*/*; do
    if [ -L "$i" ]; then continue; fi
    if [ -z "''${i##*/liblto*}" ]; then continue; fi
    echo patching "$i"
    LD_LIBRARY_PATH=$out/lib:$LIBSTDCXX_SO_DIR $LD_BINARY \
        ./patchelf --set-interpreter $LD_BINARY --set-rpath $out/lib:$LIBSTDCXX_SO_DIR --force-rpath "$i"
done

for i in $out/lib/librt-*.so $out/lib/libpcre*; do
    if [ -L "$i" ]; then continue; fi
    echo patching "$i"
    $out/bin/patchelf --set-rpath $out/lib --force-rpath "$i"
done

export PATH=$out/bin

ln -s bash $out/bin/sh
ln -s bzip2 $out/bin/bunzip2

# Provide a gunzip script.
cat > $out/bin/gunzip <<EOF
#!$out/bin/sh
exec $out/bin/gzip -d "\$@"
EOF
chmod +x $out/bin/gunzip

# Provide fgrep/egrep.
echo "#! $out/bin/sh" > $out/bin/egrep
echo "exec $out/bin/grep -E \"\$@\"" >> $out/bin/egrep
echo "#! $out/bin/sh" > $out/bin/fgrep
echo "exec $out/bin/grep -F \"\$@\"" >> $out/bin/fgrep

chmod -R 555 $out
          '')
        ];
        inherit src;
        allowedReferences = [ "out" ];
      };
    };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) bootstrapFiles boot-bash;
    inherit (pkgs.stage0) runCommand writeText;
  };

}
