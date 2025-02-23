{ fetchurl, version, src }: let

  hash = "sha256-RCgK9oZRDQUiWLVkcIBSR2HeoB+Bh0czthrpjFEkCaY=";

  # Pinned from https://github.com/oriansj/stage0-posix/commit/3189b5f325b7ef8b88e3edec7c1cde4fce73c76c
  # This 256 byte seed is the only pre-compiled binary in the bootstrap chain.
  hex0-seed = fetchurl {
    name = "hex0-seed";
    url = "https://github.com/oriansj/bootstrap-seeds/raw/b1263ff14a17835f4d12539226208c426ced4fba/POSIX/AMD64/hex0-seed";
    executable = true;
    inherit hash;
  };

in (derivation {
  name = "hex0-${version}";
  system = "x86_64-linux";
  builder = hex0-seed;
  args = [
    "${src}/AMD64/hex0_AMD64.hex0"
    (placeholder "out")
  ];

  # Ensure the untrusted hex0-seed binary produces a known-good hex0
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = hash;
}) // {
  inherit hex0-seed;
}
