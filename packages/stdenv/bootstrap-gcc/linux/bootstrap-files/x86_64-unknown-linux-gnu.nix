{
  bootstrapTools = import ../../fetchurl-bootstrap.nix {
    url = "http://tarballs.nixos.org/stdenv/x86_64-unknown-linux-gnu/82b583ba2ba2e5706b35dbe23f31362e62be2a9d/bootstrap-tools.tar.xz";
    hash = "sha256-YQlr088HPoVWBU2jpPhpIMyOyoEDZYDw1y60SGGbUM0=";
  };
  busybox = import ../../fetchurl-bootstrap.nix {
    url = "http://tarballs.nixos.org/stdenv/x86_64-unknown-linux-gnu/82b583ba2ba2e5706b35dbe23f31362e62be2a9d/busybox";
    hash = "sha256-QrTEnQTBM1Y/qV9odq8irZkQSD9uOMbs2Q5NgCvKCNQ=";
    executable = true;
  };
  tinycc = import ../../fetchurl-bootstrap.nix {
    name = "tinycc-liberated";
    url = "https://github.com/ZilchOS/bootstrap-from-tcc/releases/download/seeding-files-r004/tinycc-liberated.nar";
    hash = "sha256-oqeOU6SFYDwpdIj8MjcQ+bMuU63CHyoV9NYdyPLFxEQ=";
    unpack = true;
  };
}

