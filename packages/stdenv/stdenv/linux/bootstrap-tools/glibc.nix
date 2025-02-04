# Adapted from https://github.com/NixOS/nixpkgs
{
  system,
  bootstrapFiles,
  extraAttrs ? {},
}:

derivation (
  {
    name = "bootstrap-tools";

    inherit system;

    builder = bootstrapFiles.busybox;

    args = [
      "ash"
      "-e"
      ./glibc/unpack-bootstrap-tools.sh
    ];

    tarball = bootstrapFiles.bootstrapTools;

    allowedReferences = [ "out" bootstrapFiles.busybox ];

    # TODO: move this outside of the derivation environment
    #
    # Needed by the GCC wrapper.
    # langC = true;
    # langCC = true;
    # isGNU = true;
    # hardeningUnsupportedFlags = [
    #   "fortify3"
    #   "shadowstack"
    #   "pacret"
    #   "stackclashprotection"
    #   "trivialautovarinit"
    #   "zerocallusedregs"
    # ];
  }
  // extraAttrs
)

