core:
{
  function = { mkDrv, mkDerivationFromStdenv, buildPlatform, hostPlatform, targetPlatform }:
    {
      name ? "stdenv", shell,
      initialPath, preHook ? "",
      cc,
      setupScript ? ./setup.sh, fetchurlBoot,

      allowedRequisites ? null,
      disallowedRequisites ? [],
      ...
    }: mkDrv (self: {
      inherit name;
      # FIX: System is not expanded
      # inherit (buildPlatform) system;
      system = hostPlatform;

      builder = self.drvAttrs.shell;

      args = [ "-e" ./builder.sh ];

      setup = setupScript;

      inherit initialPath shell;

      public = {
        inherit buildPlatform hostPlatform targetPlatform;
        inherit fetchurlBoot cc;
        inherit (self.drvAttrs) shell;

        # Convenience for doing some very basic shell syntax checking by parsing a script
        # without running any commands. Because this will also skip `shopt -s extglob`
        # commands and extglob affects the Bash parser, we enable extglob always.
        shellDryRun = "${self.drvAttrs.shell} -n -O extglob";

        # TODO: add mkDerivation
        mkDerivation = mkDerivationFromStdenv self.finalPackage;
      };
    });

  dep-defaults = { lib, ... }: {
    inherit (lib.self) mkDrv mkDerivationFromStdenv;
  };
}
