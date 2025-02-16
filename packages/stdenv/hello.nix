core:
{
  function = { mkAutoTools, fetchurl, ... }: mkAutoTools (self: {
    name = "hello";
    version = "2.12.1";

    src = fetchurl {
      url = "mirror://gnu/hello/hello-${self.setup.version}.tar.gz";
      hash = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
    };
  });
  dep-defaults = { pkgs, ... }: {
    mkAutoTools = pkgs.self.mkAutoTools.onHost;
    fetchurl = import ./stdenv/fetchurl-bootstrap.nix;
  };
}
