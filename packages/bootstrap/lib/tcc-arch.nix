{ ... }:
{

  tcc_target_arch = system:
    {
      "i686-linux" = "I386";
      "x86_64-linux" = "X86_64";
      "riscv64-linux" = "RISCV64";
    }.${system} or (throw "Unsupported system: ${system}");

}

