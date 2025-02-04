{
  # Which libc to bootstrap
  libc,
  # Which platform to bootstrap for (can only be build platform)
  system,
  # The bootstrap files used to create a minimal derivation environment
  bootstrapFiles,
  # false when built by a bootstrapped corepkgs for reproducing + testing
  isFromBootstrapFiles ? false,
}:

let
  maybeDenoteProvenance = if isFromBootstrapFiles then {
    inherit isFromBootstrapFiles;
  } else {};

  args = {
    inherit system bootstrapFiles;
  };
  result =
    if libc == "glibc" then
      import ./glibc.nix args
    else if libc == "musl" then
      import ./musl.nix args
    else
      throw "unsupported libc";
in
result // maybeDenoteProvenance
