lib:
{
  function = {
    hex0,
    mkMinimalPackage,
    minimal-bootstrap-sources,
    fetchurl,
    buildPlatform,
    runPlatform,
    ...
  }: let

    stage0Arch = lib.self.platforms.stage0Arch runPlatform;
    hash = {
      "AArch64" = "sha256-XTPsoKeI6wTZAF0UwEJPzuHelWOJe//wXg4HYO0dEJo=";
      "AMD64" = "sha256-DCzZduYrix9yOeJoem/Jhz/WDzAss7UWwjZbkXJq6Ms=";
      "x86" = "sha256-DFmSpy4EYoKBSuPQRqtTsUfIUjlg794PnMrEg5stOFY=";
      "riscv64" = "sha256-BMgaiXD8bnxOTHal4RlmYKItuWUcDIwSrRuPVAnm/BE=";
      "riscv32" = "sha256-zdzWc9xgoePc2lmvXmyQBUymzUVS95Cplo0AGTb4iE0=";
    }.${stage0Arch} or (throw "Unsupported system: ${runPlatform}");

    hex0-seed = fetchurl {
      name = "hex0-seed";
      url = "https://github.com/oriansj/bootstrap-seeds/raw/cedec6b8066d1db229b6c77d42d120a23c6980ed/POSIX/${stage0Arch}/hex0-seed";
      executable = true;
      inherit hash;
    };

  in mkMinimalPackage.onRun {
    name = "hex0";
    version = "1.8.0";
    drv = {
      builder = if (buildPlatform == runPlatform)
        then hex0-seed
        else hex0.onBuild;
      args = [
        "${minimal-bootstrap-sources}/${stage0Arch}/hex0_${stage0Arch}.hex0"
        (placeholder "out")
      ];
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) fetchurl mkMinimalPackage hex0 minimal-bootstrap-sources;
  };
}
