core:
{
  function = { mkDrv, buildPlatform, hostPlatform, targetPlatform }:
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

        # Convenience for doing some very basic shell syntax checking by parsing a script
        # without running any commands. Because this will also skip `shopt -s extglob`
        # commands and extglob affects the Bash parser, we enable extglob always.
        shellDryRun = "${self.drvAttrs.shell} -n -O extglob";

        # TODO: add mkDerivation
      };
    });

  dep-defaults = { lib, ... }: {
    inherit (lib.self) mkDrv;
  };
}
