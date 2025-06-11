lib:
let
  callLibs = file: import file lib;
in {
  derivations = callLibs ./derivations.nix;
}
