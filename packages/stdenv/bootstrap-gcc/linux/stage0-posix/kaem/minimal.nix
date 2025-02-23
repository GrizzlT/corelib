{
  src,
  hex0,
  version,
}:
derivation {
  name = "kaem-minimal-${version}";
  builder = hex0;
  system = "x86_64-linux";
  args = [
    "${src}/AMD64/kaem-minimal.hex0"
    (placeholder "out")
  ];
}
