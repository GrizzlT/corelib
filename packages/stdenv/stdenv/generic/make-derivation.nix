lib:

let
  mkDerivationFromStdenv =
    stdenv:

    let
      mkDerivation = fnOrAttrs:
        lib.self.mkDrv (self: let
          setup = if lib.self.isFunction fnOrAttrs then fnOrAttrs self else fnOrAttrs;
        in setup
          // (if (setup ? name  || (setup ? pname && setup ? version)) then {
            name = if setup ? setup.name then setup.name else "${setup.pname}-${setup.version}";
          } else {})
          // {
            builder = setup.realBuilder or stdenv.shell;
            args = setup.args or ["-e" (setup.builder or ./default-builder.sh)];
            inherit stdenv;

            # inherit (stdenv.buildPlatform) system;
            system = stdenv.buildPlatform;

            public = { inherit (stdenv) buildPlatform hostPlatform targetPlatform; };
            extraAttrs.setup = setup;
          });
    in mkDerivation;
in
{
  inherit mkDerivationFromStdenv;
}
