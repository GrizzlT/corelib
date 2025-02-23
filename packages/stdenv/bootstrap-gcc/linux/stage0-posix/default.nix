{ fetchurl, ... }:
let
  inherit (import ./bootstrap-sources.nix { system = "x86_64-linux"; }) version minimal-bootstrap-sources;

  src = minimal-bootstrap-sources;

  m2libc = src + "/M2libc";

  hex0 = import ./hex0.nix { inherit fetchurl version src; };

  kaem = import ./kaem {
    inherit version kaem mescc-tools mescc-tools-extra;
    inherit (utils) writeText;
    inherit (mescc-tools-boot) kaem-unwrapped;
  };
  kaem-minimal = import ./kaem/minimal.nix { inherit version src hex0; };

  mescc-tools-boot = import ./mescc-tools-boot.nix { inherit version src hex0 m2libc; };

  mescc-tools = import ./mescc-tools (mescc-tools-boot // { inherit version src m2libc; });
  mescc-tools-extra = import ./mescc-tools-extra { inherit version src mescc-tools; inherit (mescc-tools-boot) kaem-unwrapped; };

  utils = import ./utils.nix { inherit kaem mescc-tools-extra; };
in {
  inherit kaem;

  inherit mescc-tools mescc-tools-extra;
}
