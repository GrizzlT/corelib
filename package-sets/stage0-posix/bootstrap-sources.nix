core:
core.mkPackage {

  function = { std, mkMinimalPackage, ... }: let
    version = "1.8.0";
    outputHashAlgo = "sha256";
    final = mkMinimalPackage.onHost {
      name = "stage0-posix-source";
      inherit version;

      drv = {
        name = "stage0-posix-${version}-source";
        inherit outputHashAlgo;
        outputHash = "sha256-7obetEF1aq87rxSLjI7E0cukaihEbGZocpNU8LWhE6A=";
        outputHashMode = "recursive";

        # This builder always fails, but fortunately Nix will print the
        # "builder", which is really the error message that we want the
        # user to see.
        builder = ''
          #
          #
          # Neither your store nor your substituters seems to have:
          #
          #  ${builtins.placeholder "out"}
          #
          # You can create this path from an already-bootstrapped nixpkgs
          # using the following command:
          #
          #   nix-build '<nixpkgs>' -A make-minimal-bootstrap-sources
          #
          # Or, if you prefer, you can create this file using only `git`,
          # `nix`, and `xz`.  For the commands needed in order to do this,
          # see `make-bootstrap-sources.nix`.  Once you have the manual
          # result, do:
          #
          #   nix-store --add-fixed --recursive ${outputHashAlgo} ./stage0-posix-1.8.0-source
          #
          # to add it to your store.
        '';
      };
      public = {
        rev = "Release_${version}";
        m2libc = final + "/M2libc";
        noSplice = true;
      };
    };
  in final;

  dep-defaults = { pkgs, lib, ... }: {
    inherit (lib) std;
    inherit (pkgs.self) mkMinimalPackage;
  };
}
