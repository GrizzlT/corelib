{
  bootstrapTools = import ../../fetchurl-bootstrap.nix {
    url = "http://tarballs.nixos.org/stdenv/x86_64-unknown-linux-musl/125cefd4cf8f857e5ff1aceaef9230ba578a033d/bootstrap-tools.tar.xz";
    hash = "sha256-t0W2MR7UwtPyYEGcRo9UOuXfaP4uUZKZXEmYGcBOuOA=";
  };
  busybox = import ../../fetchurl-bootstrap.nix {
    url = "http://tarballs.nixos.org/stdenv/x86_64-unknown-linux-musl/125cefd4cf8f857e5ff1aceaef9230ba578a033d/busybox";
    hash = "sha256-0U2r3EU61oqhs+oyzFABIFTCVqXOWSP0qEtnyHwjzm0=";
    executable = true;
  };
}

