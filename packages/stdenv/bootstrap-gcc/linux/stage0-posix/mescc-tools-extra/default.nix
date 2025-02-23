{
  kaem-unwrapped,
  mescc-tools,
  src,
  version,
}:
let
  m2libcArch = "amd64";
  m2libcOS = "linux";
in
derivation {
  inherit
    src
    mescc-tools
    m2libcArch
    m2libcOS
    ;
  name = "mescc-tools-extra-${version}";
  builder = kaem-unwrapped;
  system = "x86_64-linux";
  args = [
    "--verbose"
    "--strict"
    "--file"
    ./build.kaem
  ];
}
