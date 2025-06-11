lib:
{
  function = {
    coreutils,
    runCommand,
    ...
  }: let
    inherit (lib.std.asserts) assertMsg;
    inherit (lib.std.strings) hasPrefix escapeShellArg;
  in {
    __functor = _: {
        name, # the name of the derivation
        text,
        executable ? false, # run chmod +x ?
        destination ? "", # relative path appended to $out eg "/bin/foo"
        public ? {},
        allowSubstitutes ? false,
        preferLocalBuild ? true,
      }:
      assert assertMsg (destination != "" -> (hasPrefix "/" destination && destination != "/")) ''
        destination must be an absolute path, relative to the derivation's out path,
        got '${destination}' instead.

        Ensure that the path starts with a / and specifies at least the filename.
      '';

      runCommand.onBuild {
        inherit name;
        env = {
          inherit text executable allowSubstitutes preferLocalBuild;
          passAsFile = ["text"];
        };
        tools = [ coreutils.onBuild ];
        buildCommand = /* bash */ ''
          target=$out${escapeShellArg destination}
          mkdir -p "$(dirname "$target")"

          if [ -e "$textPath" ]; then
            mv "$textPath" "$target"
          else
            echo -n "$text" > "$target"
          fi

          if [ -n "$executable" ]; then
            chmod +x "$target"
          fi
        '';
        public = public // {
          inherit text;
          __elaborate = false;
        };
      };
    __elaborate = false;
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self) runCommand coreutils;
  };
}
