{
  # Which platform to bootstrap for (can only be build platform)
  system,
  # The bootstrap files used to create a minimal derivation environment
  bootstrapFiles,
}:

let
  result = derivation {
    name = "bootstrap-tools";

    inherit system;

    builder = bootstrapFiles.busybox;

    args = [
      "ash"
      "-e"
      ./unpack-bootstrap-tools.sh
    ];

    tarball = bootstrapFiles.bootstrapTools;
    tinycc = bootstrapFiles.tinycc;

    allowedReferences = [ "out" bootstrapFiles.busybox bootstrapFiles.tinycc ];
  };
in
result
