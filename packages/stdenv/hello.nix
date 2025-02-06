core:
{
  function = { mkDerivation, fetchurl, ... }: mkDerivation (self: {
    pname = "hello";
    version = "2.12.1";

    src = fetchurl {
      url = "mirror://gnu/hello/hello-${self.setup.version}.tar.gz";
      hash = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
    };
  });
  dep-defaults = { pkgs, ... }: {
    inherit (pkgs.self.stdenv.onHostForTarget) mkDerivation;
    fetchurl = import ./stdenv/fetchurl-bootstrap.nix;
  };
}
