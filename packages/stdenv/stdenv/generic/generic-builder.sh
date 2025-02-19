######################################################################
# Shell options.

export SHELL="$shell"
export CONFIG_SHELL="$SHELL" # For autotools

# shellcheck shell=bash
__nixpkgs_setup_set_original=$-
set -eu
set -o pipefail


if [[ -n "${BASH_VERSINFO-}" && "${BASH_VERSINFO-}" -lt 4 ]]; then
    echo "Detected Bash version that isn't supported by Nixpkgs (${BASH_VERSION})"
    echo "Please install Bash 4 or greater to continue."
    exit 1
fi

shopt -s inherit_errexit

# $NIX_DEBUG must be a documented integer level, if set, so we can use it safely as an integer.
# See the `Verbosity` enum in the Nix source for these levels.
if ! [[ -z ${NIX_DEBUG-} || $NIX_DEBUG == [0-7] ]]; then
    printf 'The `NIX_DEBUG` environment variable has an unexpected value: %s\n' "${NIX_DEBUG}"
    echo "It can only be unset or an integer between 0 and 7."
    exit 1
fi

if [[ ${NIX_DEBUG:-0} -ge 6 ]]; then
    set -x
fi

# Wildcard expansions that don't match should expand to an empty list.
# This ensures that, for instance, "for i in *; do ...; done" does the
# right thing.
shopt -s nullglob

######################################################################
# Initialisation.

source "$buildUtils"

PATH=
for i in $initialPath; do
  if [ "$i" = / ]; then i=; fi
  addToSearchPath PATH "$i/bin"
done
unset i


# Define exit behavior, should come from $buildUtils
trap "exitHandler" EXIT


# Set a fallback default value for SOURCE_DATE_EPOCH, used by some build tools
# to provide a deterministic substitute for the "current" time. Note that
# 315532800 = 1980-01-01 12:00:00. We use this date because python's wheel
# implementation uses zip archive and zip does not support dates going back to
# 1970.
export SOURCE_DATE_EPOCH
: "${SOURCE_DATE_EPOCH:=315532800}"

# Set the TZ (timezone) environment variable, otherwise commands like
# `date' will complain (e.g., `Tue Mar 9 10:01:47 Local time zone must
# be set--see zic manual page 2004').
export TZ=UTC


# Normalize the NIX_BUILD_CORES variable. The value might be 0, which
# means that we're supposed to try and auto-detect the number of
# available CPU cores at run-time.
NIX_BUILD_CORES="${NIX_BUILD_CORES:-1}"
if ((NIX_BUILD_CORES <= 0)); then
  guess=$(nproc 2>/dev/null || true)
  ((NIX_BUILD_CORES = guess <= 0 ? 1 : guess))
fi
export NIX_BUILD_CORES


# Prevent SSL libraries from using certificates in /etc/ssl, unless set explicitly.
# Leave it in impure shells for convenience.
if [[ -z "${NIX_SSL_CERT_FILE:-}" && "${IN_NIX_SHELL:-}" != "impure" ]]; then
  export NIX_SSL_CERT_FILE=/no-cert-file.crt
fi
# Another variant left for compatibility.
if [[ -z "${SSL_CERT_FILE:-}" && "${IN_NIX_SHELL:-}" != "impure" ]]; then
  export SSL_CERT_FILE=/no-cert-file.crt
fi




######################################################################
# What follows is the generic builder.

function runBuild() {
  source "$actualBuild"
}

runBuild




######################################################################
# Reset shell

# Restore the original options for nix-shell
[[ $__nixpkgs_setup_set_original == *e* ]] || set +e
[[ $__nixpkgs_setup_set_original == *u* ]] || set +u
unset -v __nixpkgs_setup_set_original

