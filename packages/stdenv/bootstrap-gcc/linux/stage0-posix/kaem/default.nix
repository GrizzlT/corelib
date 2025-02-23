{
  writeText,
  kaem,
  kaem-unwrapped,
  mescc-tools,
  mescc-tools-extra,
  version,
}:

# Once mescc-tools-extra is available we can install kaem at /bin/kaem
# to make it findable in environments
(derivation {
  inherit kaem-unwrapped;
  name = "kaem-${version}";
  builder = kaem-unwrapped;
  system = "x86_64-linux";
  args = [
    "--verbose"
    "--strict"
    "--file"
    (builtins.toFile "kaem-wrapper.kaem" ''
      mkdir -p ''${out}/bin
      cp ''${kaem-unwrapped} ''${out}/bin/kaem
      chmod 555 ''${out}/bin/kaem
    '')
  ];
  PATH = [ "${mescc-tools-extra}/bin" ];
}) // {
  runCommand =
    name: drvAttrs: buildCommand:
    derivation (
      {
        inherit name;

        builder = "${kaem}/bin/kaem";
        system = "x86_64-linux";
        args = [
          "--verbose"
          "--strict"
          "--file"
          (writeText "${name}-builder" buildCommand)
        ];

        PATH = builtins.concatStringsSep ":" (map (v: "${v}/bin") (
          (drvAttrs.binaries or [ ])
          ++ [
            kaem
            mescc-tools
            mescc-tools-extra
          ]
        ));
      }
      // (builtins.removeAttrs drvAttrs [ "binaries" ])
    );
}
