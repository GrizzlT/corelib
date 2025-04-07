{ self, std, ... }:
let
  self' = self.platforms;

  inherit (std.strings)
    toLower
    ;
  inherit (std.lists)
    elem
    ;

in {

  platforms = [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "riscv64-linux"
    "riscv32-linux"
  ];

  # system arch as used within the stage0 project
  stage0Arch = system: {
    "aarch64-linux" = "AArch64";
    "i686-linux" = "x86";
    "x86_64-linux" = "AMD64";
    "riscv64-linux" = "riscv64";
    "riscv32-linux" = "riscv32";
  }.${system} or (throw "Unsupported system: ${system}");

    # lower-case form is widely used by m2libc
  m2libcArch = system: toLower (self'.stage0Arch system);

  # Passed to M2-Mesoplanet as --operating-system
  m2libcOS = system:
    if elem system self'.platforms then "linux" else throw "Unsupported system: ${system}";

  baseAddress = system:
    {
      "aarch64-linux" = "0x00600000";
      "i686-linux" = "0x08048000";
      "x86_64-linux" = "0x00600000";
      "riscv64-linux" = "0x00600000";
      "riscv32-linux" = "0x00600000";
    }
    .${system} or (throw "Unsupported system: ${system}");
}
