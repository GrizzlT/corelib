lib:
let
  callLibs = file: import file lib;
in {
  mes-arch = callLibs ./mes-arch.nix;
  tcc-arch = callLibs ./tcc-arch.nix;
}
