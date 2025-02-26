# Adapted from https://github.com/NixOS/nix
#
# Similar to <nix/fetchurl.nix>
# Should only be used to bootstrap the initial C toolchain

{ url
, hash ? "" # an SRI hash

# Legacy hash specification
, md5 ? "", sha1 ? "", sha256 ? "", sha512 ? ""
, outputHash ?
    if hash != "" then hash else if sha512 != "" then sha512 else if sha1 != "" then sha1 else if md5 != "" then md5 else sha256
, outputHashAlgo ?
    if hash != "" then "" else if sha512 != "" then "sha512" else if sha1 != "" then "sha1" else if md5 != "" then "md5" else "sha256"

, executable ? false
, unpack ? false
, name ? baseNameOf (toString url)
}:

derivation ({
  builder = "builtin:fetchurl";

  # New-style output content requirements.
  outputHashMode = if unpack || executable then "recursive" else "flat";

  inherit name url executable unpack;

  system = "builtin";

  # No need to double the amount of network traffic
  preferLocalBuild = true;

  # This attribute does nothing; it's here to avoid changing evaluation results.
  # This impurity is okay since this is a fixed-output derivation (FOD)
  impureEnvVars = [
    "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy"
  ];

  # To make "nix-prefetch-url" work.
  urls = [ url ];
} // ({ inherit outputHashAlgo outputHash; }))

