# Build steps adapted from https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/tcc-0.9.27/tcc-0.9.27.kaem
#
# SPDX-FileCopyrightText: 2021-22 fosslinux <fosslinux@aussies.space>
#
# SPDX-License-Identifier: GPL-3.0-or-later

core:
{
  function = {
    fetchurl,
    runCommand,
    tinycc-bootstrappable,

    buildPlatform,
    hostPlatform,
    targetPlatform,
    autoCall,
    ...
  }:
  let
    inherit (autoCall (import ./common.nix) { }) buildTinyccMes;

    version = "unstable-2023-04-20";
    rev = "86f3d8e33105435946383aee52487b5ddf918140";

    tarball = fetchurl {
      url = "https://repo.or.cz/tinycc.git/snapshot/${rev}.tar.gz";
      sha256 = "11idrvbwfgj1d03crv994mpbbbyg63j1k64lw1gjy7mkiifw2xap";
    };

    src =
      (runCommand.onHost "tinycc-${version}-source" { } /*sh*/ ''
        ungz --file ${tarball} --output tinycc.tar
        mkdir -p ''${out}
        cd ''${out}
        untar --file ''${NIX_BUILD_TOP}/tinycc.tar

        # Patch
        cd tinycc-${builtins.substring 0 7 rev}
        # Static link by default
        replace --file libtcc.c --output libtcc.c --match-on "s->ms_extensions = 1;" --replace-with "s->ms_extensions = 1; s->static_link = 1;"
      '')
      + "/tinycc-${builtins.substring 0 7 rev}";

    tccdefs = runCommand.onBuild "tccdefs-${version}" { } ''
      mkdir ''${out}
      ${tinycc-bootstrappable.onBuild.compiler}/bin/tcc \
        -B ${tinycc-bootstrappable.onBuild.libs}/lib \
        -DC2STR \
        -o c2str \
        ${src}/conftest.c
      ./c2str ${src}/include/tccdefs.h ''${out}/tccdefs_.h
    '';

    tinycc-mes-boot = buildTinyccMes {
      name = "tinycc-mes-boot";
      inherit src version;
      prev = tinycc-bootstrappable.onBuild;
      buildOptions = [
        "-D HAVE_BITFIELD=1"
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
        "-D HAVE_SETJMP=1"
        "-D CONFIG_TCC_PREDEFS=1"
        "-I ${tccdefs}"
        "-D CONFIG_TCC_SEMLOCK=0"
      ];
      libtccBuildOptions = [
        "-D HAVE_FLOAT=1"
        "-D HAVE_LONG_LONG=1"
        "-D CONFIG_TCC_PREDEFS=1"
        "-I ${tccdefs}"
        "-D CONFIG_TCC_SEMLOCK=0"
      ];
    };
  in
    if buildPlatform == hostPlatform
    then (if hostPlatform == targetPlatform
      then buildTinyccMes {
        name = "tinycc-mes";
        inherit src version;
        prev = tinycc-mes-boot;
        buildOptions = [
          "-std=c99"
          "-D HAVE_BITFIELD=1"
          "-D HAVE_FLOAT=1"
          "-D HAVE_LONG_LONG=1"
          "-D HAVE_SETJMP=1"
          "-D CONFIG_TCC_PREDEFS=1"
          "-I ${tccdefs}"
          "-D CONFIG_TCC_SEMLOCK=0"
        ];
        libtccBuildOptions = [
          "-D HAVE_FLOAT=1"
          "-D HAVE_LONG_LONG=1"
          "-D CONFIG_TCC_PREDEFS=1"
          "-I ${tccdefs}"
          "-D CONFIG_TCC_SEMLOCK=0"
        ];
      }
      else null)
    else null;

  dep-defaults = { pkgs, lib, autoCall, ... }: {
    inherit autoCall;
    inherit (pkgs.stage0) runCommand;
    inherit (pkgs.self) tinycc-bootstrappable;
    fetchurl = import ../../stage0-posix/bootstrap-fetchurl.nix;
  };
}


