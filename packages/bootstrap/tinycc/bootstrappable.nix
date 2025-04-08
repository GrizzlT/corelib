# Bootstrappable TCC is a fork from mainline TCC development
# that can be compiled by MesCC

# Build steps adapted from https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/tcc-0.9.26/tcc-0.9.26.kaem
#
# SPDX-FileCopyrightText: 2021-22 fosslinux <fosslinux@aussies.space>
#
# SPDX-License-Identifier: GPL-3.0-or-later

core:
{
  function = {
    fetchurl,
    runCommand,
    mes-arch,
    tcc-arch,
    mes,
    mes-libc,
    buildPlatform,
    hostPlatform,
    autoCall,
    ...
  }:
  let
    inherit (autoCall (import ./common.nix) { }) buildTinyccMes recompileLibc;

    tcc_target_arch = tcc-arch.tcc_target_arch hostPlatform;
    mes_cpu = mes-arch.mes_cpu hostPlatform;

    name = "tinycc-boot-mes";
    version = "unstable-2023-04-20";
    rev = "80114c4da6b17fbaabb399cc29f427e368309bc8";

    tarball = fetchurl {
      url = "https://gitlab.com/janneke/tinycc/-/archive/${rev}/tinycc-${rev}.tar.gz";
      sha256 = "1a0cw9a62qc76qqn5sjmp3xrbbvsz2dxrw21lrnx9q0s74mwaxbq";
    };
    src =
      (runCommand.onHost "tinycc-bootstrappable-${version}-source" { } /*sh*/ ''
        ungz --file ${tarball} --output tinycc.tar
        mkdir -p ''${out}
        cd ''${out}
        untar --file ''${NIX_BUILD_TOP}/tinycc.tar

        # Patch
        cd tinycc-${rev}
        # Static link by default
        replace --file libtcc.c --output libtcc.c --match-on "s->ms_extensions = 1;" --replace-with "s->ms_extensions = 1; s->static_link = 1;"
      '')
      + "/tinycc-${rev}";

    tinycc-boot-mes = rec {
      compiler =
        runCommand.onHost "${name}-${version}" {}
          ''
            catm config.h
            ${mes.onBuild}/bin/mes --no-auto-compile -e main ${mes.onBuild.srcPost.bin}/bin/mescc.scm -- \
              -S \
              -o tcc.s \
              -I . \
              -D BOOTSTRAP=1 \
              -I ${src} \
              -D TCC_TARGET_${tcc_target_arch}=1 \
              -D inline= \
              -D CONFIG_TCCDIR=\"\" \
              -D CONFIG_SYSROOT=\"\" \
              -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
              -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
              -D CONFIG_TCC_LIBPATHS=\"{B}\" \
              -D CONFIG_TCC_SYSINCLUDEPATHS=\"${mes-libc.onHost}/include\" \
              -D TCC_LIBGCC=\"${mes-libc.onHost}/lib/${mes_cpu}-mes/libc.a\" \
              -D CONFIG_TCC_LIBTCC1_MES=0 \
              -D CONFIG_TCCBOOT=1 \
              -D CONFIG_TCC_STATIC=1 \
              -D CONFIG_USE_LIBGCC=1 \
              -D TCC_MES_LIBC=1 \
              -D TCC_VERSION=\"${version}\" \
              -D ONE_SOURCE=1 \
              ${src}/tcc.c
            mkdir -p ''${out}/bin
            ${mes.onBuild}/bin/mes --no-auto-compile -e main ${mes.onBuild.srcPost.bin}/bin/mescc.scm -- \
              -L ${mes.onHost.libs}/lib \
              -l c+tcc \
              -o ''${out}/bin/tcc \
              tcc.s
          '';

      libs = recompileLibc {
        inherit name version;
        tcc = compiler;
        src = mes-libc.onHost;
        libtccOptions = mes-libc.onHost.CFLAGS;
      };
    };

    # Bootstrap stage build flags obtained from
    # https://gitlab.com/janneke/tinycc/-/blob/80114c4da6b17fbaabb399cc29f427e368309bc8/boot.sh

    tinycc-boot0 = buildTinyccMes {
      name = "tinycc-boot0";
      inherit src version;
      prev = tinycc-boot-mes;
      buildOptions = [
        "-D HAVE_LONG_LONG_STUB=1"
        "-D HAVE_SETJMP=1"
      ];
      libtccBuildOptions = [
        "-D HAVE_LONG_LONG_STUB=1"
      ];
    };

    tinycc-boot1 = buildTinyccMes {
      name = "tinycc-boot1";
      inherit src version;
      prev = tinycc-boot0;
      buildOptions = [
        "-D HAVE_BITFIELD=1"
        "-D HAVE_LONG_LONG=1"
        "-D HAVE_SETJMP=1"
      ];
      libtccBuildOptions = [
        "-D HAVE_LONG_LONG=1"
      ];
    };

    tinycc-boot2 = buildTinyccMes {
      name = "tinycc-boot2";
      inherit src version;
      prev = tinycc-boot1;
      buildOptions = [
        "-D HAVE_BITFIELD=1"
        "-D HAVE_FLOAT_STUB=1"
        "-D HAVE_LONG_LONG=1"
        "-D HAVE_SETJMP=1"
      ];
      libtccBuildOptions = [
        "-D HAVE_FLOAT_STUB=1"
        "-D HAVE_LONG_LONG=1"
      ];
    };

    tinycc-boot3 = buildTinyccMes {
      name = "tinycc-boot3";
      inherit src version;
      prev = tinycc-boot2;
      buildOptions = [
        "-D HAVE_BITFIELD=1"
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
        "-D HAVE_SETJMP=1"
      ];
      libtccBuildOptions = [
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
      ];
    };
  in
    if buildPlatform == hostPlatform
    then buildTinyccMes {
      name = "tinycc-bootstrappable";
      inherit src version;
      prev = tinycc-boot3;
      buildOptions = [
        "-D HAVE_BITFIELD=1"
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
        "-D HAVE_SETJMP=1"
      ];
      libtccBuildOptions = [
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
      ];
    }
    else null;

  dep-defaults = { pkgs, lib, autoCall, ... }: {
    inherit autoCall;
    inherit (lib.self) mes-arch tcc-arch;
    inherit (pkgs.stage0) runCommand;
    inherit (pkgs.self) mes mes-libc;
    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}

