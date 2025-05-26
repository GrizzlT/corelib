{ ... }:
{

  mes_cpu = system:
    {
      "i686-linux" = "x86";
      "x86_64-linux" = "x86_64";
      "riscv64-linux" = "riscv64";
      "riscv32-linux" = "riscv32";
    }.${system} or (throw "Unsupported system: ${system}");

}

