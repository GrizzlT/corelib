core:
core.mkPackage {
  function = {
    platforms,
    hex0,
    mkMinimalPackage,
    src,
    fetchurl,
    buildPlatform,
    hostPlatform,
    ...
  }: let

    stage0Arch = platforms.stage0Arch hostPlatform;
    hash = {
      "AArch64" = "sha256-XTPsoKeI6wTZAF0UwEJPzuHelWOJe//wXg4HYO0dEJo=";
      "AMD64" = "sha256-DCzZduYrix9yOeJoem/Jhz/WDzAss7UWwjZbkXJq6Ms=";
      "x86" = "sha256-DFmSpy4EYoKBSuPQRqtTsUfIUjlg794PnMrEg5stOFY=";
      "riscv64" = "sha256-BMgaiXD8bnxOTHal4RlmYKItuWUcDIwSrRuPVAnm/BE=";
      "riscv32" = "sha256-zdzWc9xgoePc2lmvXmyQBUymzUVS95Cplo0AGTb4iE0=";
    }.${stage0Arch} or (throw "Unsupported system: ${hostPlatform}");

    hex0-seed = fetchurl {
      name = "hex0-seed";
      url = "https://github.com/oriansj/bootstrap-seeds/raw/cedec6b8066d1db229b6c77d42d120a23c6980ed/POSIX/${stage0Arch}/hex0-seed";
      executable = true;
      inherit hash;
    };

  in mkMinimalPackage.onHost {
    name = "hex0";
    version = "1.8.0";
    drv = {
      builder = if (buildPlatform == hostPlatform)
        then hex0-seed
        else hex0.onBuild;
      args = [
        "${src}/${stage0Arch}/hex0_${stage0Arch}.hex0"
        (placeholder "out")
      ];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    };
  };

  dep-defaults = { pkgs, lib, ... }: {
    src = pkgs.self.minimal-bootstrap-sources;
    inherit (pkgs.self) fetchurl mkMinimalPackage hex0;
    inherit (lib.self) platforms;
  };
}
