# Ported from Nixpkgs by GrizzlT
#
# Mes --- Maxwell Equations of Software
# Copyright © 2017,2019 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2017,2019 Jeremiah Orians
#
# This file is part of Mes.
#
# Mes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# Mes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mes.  If not, see <http://www.gnu.org/licenses/>.

# This is a translation of stage0-posix/stage0-posix/x86/mescc-tools-mini-kaem.kaem to nix
# https://github.com/oriansj/stage0-posix-x86/blob/56e6b8df3e95f4bc04f8b420a4cd8c82c70b9efa/mescc-tools-mini-kaem.kaem
#
# We have access to mini-kaem at this point but it doesn't support substituting
# environment variables. Without variables there's no way of passing in store inputs,
# or the $out path, other than as command line arguments directly

# Warning all binaries prior to the use of blood-elf will not be readable by
# Objdump, you may need to use ndism or gdb to view the assembly in the binary.

core:
core.mkPackage {
  function = {
    platforms,
    mescc-tools-boot,
    mescc-tools-boot2,
    m2libc,
    src,
    mkMinimalPackage,
    buildPlatform, hostPlatform, targetPlatform,
    ...
  }: let
    inherit (mescc-tools-boot.onBuild)
      M2
      blood-elf-0
      M1-0
      ;
    inherit (mescc-tools-boot2.onBuild)
      M1
      hex2
      ;
    inherit (mescc-tools-boot2.onHost)
      M1-macro-1_M1
      M1-macro-1-footer_M1
      M1-macro-1_hex2
      hex2_linker-2_M1
      hex2_linker-2-footer_M1
      hex2_linker-2_hex2
      kaem_M1
      kaem-footer_M1
      kaem_hex2
      ;

    out = placeholder "out";

    baseAddress = platforms.baseAddress hostPlatform;
    m2libcArch = platforms.m2libcArch hostPlatform;

    endianFlag = {
      "aarch64-linux" = "--little-endian";
      "i686-linux" = "--little-endian";
      "x86_64-linux" = "--little-endian";
      "riscv64-linux" = "--little-endian";
      "riscv32-linux" = "--little-endian";
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    bloodFlags = {
      "aarch64-linux" = ["--64"];
      "i686-linux" = [];
      "x86_64-linux" = ["--64"];
      "riscv64-linux" = ["--64"];
      "riscv32-linux" = [];
    }.${hostPlatform} or (throw "Unsupported system: ${hostPlatform}");

    run = name: builder: args: mkMinimalPackage.onHost {
      inherit name;
      version = "1.6.0";
      drv = {
        inherit builder args;
      };
      public = {
        targetPlatform = hostPlatform;
      };
    };

    # TODO: compile for different architecture based on platform triple
  in {

    inherit buildPlatform hostPlatform;

    ## Stages copied from nixpkgs

    # This is the last stage where we will be using the handwritten hex2 and instead
    # be using the far more powerful, cross-platform version with a bunch more goodies

    ###################################
    # Phase-9 Build M1 from C sources #
    ###################################

    M1-macro-1_M1 = run "M1-macro-1.M1" M2 [
      "--architecture"
      m2libcArch
      "-f"
      "${m2libc}/sys/types.h"
      "-f"
      "${m2libc}/stddef.h"
      "-f"
      "${m2libc}/${m2libcArch}/linux/fcntl.c"
      "-f"
      "${m2libc}/fcntl.c"
      "-f"
      "${m2libc}/${m2libcArch}/linux/unistd.c"
      "-f"
      "${m2libc}/string.c"
      "-f"
      "${m2libc}/stdlib.c"
      "-f"
      "${m2libc}/stdio.h"
      "-f"
      "${m2libc}/stdio.c"
      "-f"
      "${m2libc}/bootstrappable.c"
      "-f"
      "${src}/mescc-tools/stringify.c"
      "-f"
      "${src}/mescc-tools/M1-macro.c"
      "--debug"
      "-o"
      out
    ];

    M1-macro-1-footer_M1 = run "M1-macro-1-footer.M1" blood-elf-0 (
      bloodFlags
      ++ [
        "-f"
        M1-macro-1_M1
        endianFlag
        "-o"
        out
      ]
    );

    M1-macro-1_hex2 = run "M1-macro-1.hex2" M1-0 [
      "--architecture"
      m2libcArch
      endianFlag
      "-f"
      "${m2libc}/${m2libcArch}/${m2libcArch}_defs.M1"
      "-f"
      "${m2libc}/${m2libcArch}/libc-full.M1"
      "-f"
      M1-macro-1_M1
      "-f"
      M1-macro-1-footer_M1
      "-o"
      out
    ];

    ######################################
    # Phase-10 Build hex2 from C sources #
    ######################################

    hex2_linker-2_M1 = run "hex2_linker-2.M1" M2 [
      "--architecture"
      m2libcArch
      "-f"
      "${m2libc}/sys/types.h"
      "-f"
      "${m2libc}/stddef.h"
      "-f"
      "${m2libc}/${m2libcArch}/linux/unistd.c"
      "-f"
      "${m2libc}/${m2libcArch}/linux/fcntl.c"
      "-f"
      "${m2libc}/fcntl.c"
      "-f"
      "${m2libc}/${m2libcArch}/linux/sys/stat.c"
      "-f"
      "${m2libc}/stdlib.c"
      "-f"
      "${m2libc}/stdio.h"
      "-f"
      "${m2libc}/stdio.c"
      "-f"
      "${m2libc}/bootstrappable.c"
      "-f"
      "${src}/mescc-tools/hex2.h"
      "-f"
      "${src}/mescc-tools/hex2_linker.c"
      "-f"
      "${src}/mescc-tools/hex2_word.c"
      "-f"
      "${src}/mescc-tools/hex2.c"
      "--debug"
      "-o"
      out
    ];

    hex2_linker-2-footer_M1 = run "hex2_linker-2-footer.M1" blood-elf-0 (
      bloodFlags
      ++ [
        "-f"
        hex2_linker-2_M1
        endianFlag
        "-o"
        out
      ]
    );

    hex2_linker-2_hex2 = run "hex2_linker-2.hex2" M1 [
      "--architecture"
      m2libcArch
      endianFlag
      "-f"
      "${m2libc}/${m2libcArch}/${m2libcArch}_defs.M1"
      "-f"
      "${m2libc}/${m2libcArch}/libc-full.M1"
      "-f"
      hex2_linker-2_M1
      "-f"
      hex2_linker-2-footer_M1
      "-o"
      out
    ];

    ######################################
    # Phase-11 Build kaem from C sources #
    ######################################

    kaem_M1 = run "kaem.M1" M2 [
      "--architecture"
      m2libcArch
      "-f"
      "${m2libc}/sys/types.h"
      "-f"
      "${m2libc}/stddef.h"
      "-f"
      "${m2libc}/string.c"
      "-f"
      "${m2libc}/${m2libcArch}/linux/unistd.c"
      "-f"
      "${m2libc}/${m2libcArch}/linux/fcntl.c"
      "-f"
      "${m2libc}/fcntl.c"
      "-f"
      "${m2libc}/stdlib.c"
      "-f"
      "${m2libc}/stdio.h"
      "-f"
      "${m2libc}/stdio.c"
      "-f"
      "${m2libc}/bootstrappable.c"
      "-f"
      "${src}/mescc-tools/Kaem/kaem.h"
      "-f"
      "${src}/mescc-tools/Kaem/variable.c"
      "-f"
      "${src}/mescc-tools/Kaem/kaem_globals.c"
      "-f"
      "${src}/mescc-tools/Kaem/kaem.c"
      "--debug"
      "-o"
      out
    ];

    kaem-footer_M1 = run "kaem-footer.M1" blood-elf-0 (
      bloodFlags
      ++ [
        "-f"
        kaem_M1
        endianFlag
        "-o"
        out
      ]
    );

    kaem_hex2 = run "kaem.hex2" M1 [
      "--architecture"
      m2libcArch
      endianFlag
      "-f"
      "${m2libc}/${m2libcArch}/${m2libcArch}_defs.M1"
      "-f"
      "${m2libc}/${m2libcArch}/libc-full.M1"
      "-f"
      kaem_M1
      "-f"
      kaem-footer_M1
      "-o"
      out
    ];

    kaem-unwrapped = run "kaem-unwrapped" hex2 [
      "--architecture"
      m2libcArch
      endianFlag
      "-f"
      "${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2"
      "-f"
      kaem_hex2
      "--base-address"
      baseAddress
      "-o"
      out
    ];

  } // (if buildPlatform == hostPlatform then let
    inherit (mescc-tools-boot.onBuild) hex2-1;
  in {

    M1 = run "M1" hex2-1 [
      "--architecture"
      m2libcArch
      endianFlag
      "--base-address"
      baseAddress
      "-f"
      "${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2"
      "-f"
      M1-macro-1_hex2
      "-o"
      out
    ];

    hex2 = run "hex2" hex2-1 [
      "--architecture"
      m2libcArch
      endianFlag
      "--base-address"
      baseAddress
      "-f"
      "${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2"
      "-f"
      hex2_linker-2_hex2
      "-o"
      out
    ];

  } else let
    hex2_build = mescc-tools-boot2.onBuild.hex2;
  in {

    M1 = run "M1" hex2_build [
      "--architecture"
      m2libcArch
      endianFlag
      "--base-address"
      baseAddress
      "-f"
      "${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2"
      "-f"
      M1-macro-1_hex2
      "-o"
      out
    ];

    hex2 = run "hex2" hex2_build [
      "--architecture"
      m2libcArch
      endianFlag
      "--base-address"
      baseAddress
      "-f"
      "${m2libc}/${m2libcArch}/ELF-${m2libcArch}-debug.hex2"
      "-f"
      hex2_linker-2_hex2
      "-o"
      out
    ];

  });

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib.self) platforms;
    inherit (pkgs.self) mkMinimalPackage mescc-tools-boot mescc-tools-boot2;
    src = pkgs.self.minimal-bootstrap-sources.onHost;
    m2libc = pkgs.self.minimal-bootstrap-sources.onHost.m2libc;
  };
}
