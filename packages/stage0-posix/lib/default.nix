lib:
let
  callLibs = file: import file lib;
in {
  platforms = callLibs ./platforms.nix;
  derivations = callLibs ./derivations.nix;
}
