core:
core.mkPackage {
  function = { platforms, hostPlatform, mkMinimalPackage, src, fetchurl, ... }: let

    stage0Arch = platforms.stage0Arch hostPlatform;
    hash = {
      "AArch64" = "sha256-XTPsoKeI6wTZAF0UwEJPzuHelWOJe//wXg4HYO0dEJo=";
      "AMD64" = "sha256-RCgK9oZRDQUiWLVkcIBSR2HeoB+Bh0czthrpjFEkCaY=";
      "x86" = "sha256-QU3RPGy51W7M2xnfFY1IqruKzusrSLU+L190ztN6JW8=";
    }.${stage0Arch} or (throw "Unsupported system: ${hostPlatform}");

    hex0-seed = fetchurl {
      name = "hex0-seed";
      url = "https://github.com/oriansj/bootstrap-seeds/raw/b1263ff14a17835f4d12539226208c426ced4fba/POSIX/${stage0Arch}/hex0-seed";
      executable = true;
      inherit hash;
    };

  in mkMinimalPackage.onHost {
    name = "hex0";
    version = "1.6.0";
    drv = {
      builder = hex0-seed;
      args = [
        "${src}/${stage0Arch}/hex0_${stage0Arch}.hex0"
        (placeholder "out")
      ];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    };
    public = {
      inherit hex0-seed;
    };
  };

  dep-defaults = { pkgs, lib, ... }: {
    src = pkgs.self.minimal-bootstrap-sources.onHost;
    inherit (pkgs.self) mkMinimalPackage;
    inherit (lib.self) platforms;
    fetchurl = import ./bootstrap-fetchurl.nix;
  };
}
