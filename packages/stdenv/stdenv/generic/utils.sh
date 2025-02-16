######################################################################
# Logging.

# Prints a command such that all word splits are unambiguous. We need
# to split the command in three parts because the middle format string
# will be, and must be, repeated for each argument. The first argument
# goes before the ':' and is just for convenience.
echoCmd() {
    printf "%s:" "$1"
    shift
    printf ' %q' "$@"
    echo
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlError` in the Nix source.
nixErrorLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 0 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlWarn` in the Nix source.
nixWarnLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 1 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlNotice` in the Nix source.
nixNoticeLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 2 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlInfo` in the Nix source.
nixInfoLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 3 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlTalkative` in the Nix source.
nixTalkativeLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 4 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlChatty` in the Nix source.
nixChattyLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 5 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlDebug` in the Nix source.
nixDebugLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 6 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

# All provided arguments are joined with a space then directed to $NIX_LOG_FD, if it's set.
# Corresponds to `Verbosity::lvlVomit` in the Nix source.
nixVomitLog() {
    if [[ -z ${NIX_LOG_FD-} ]] || [[ ${NIX_DEBUG:-0} -lt 7 ]]; then return; fi
    printf "%s\n" "$*" >&"$NIX_LOG_FD"
}

######################################################################
# Error handling.

exitHandler() {
    exitCode="$?"
    set +e

    if [ -n "${showBuildStats:-}" ]; then
        read -r -d '' -a buildTimes < <(times)
        echo "build times:"
        echo "user time for the shell             ${buildTimes[0]}"
        echo "system time for the shell           ${buildTimes[1]}"
        echo "user time for all child processes   ${buildTimes[2]}"
        echo "system time for all child processes ${buildTimes[3]}"
    fi

    if (( "$exitCode" != 0 )); then

        # If the builder had a non-zero exit code and
        # $succeedOnFailure is set, create the file
        # ‘$out/nix-support/failed’ to signal failure, and exit
        # normally.  Otherwise, return the original exit code.
        if [ -n "${succeedOnFailure:-}" ]; then
            echo "build failed with exit code $exitCode (ignored)"
            mkdir -p "$out/nix-support"
            printf "%s" "$exitCode" > "$out/nix-support/failed"
            exit 0
        fi

        # TODO: add user failure handle?
    fi

    return "$exitCode"
}

######################################################################
# Helper functions.


addToSearchPathWithCustomDelimiter() {
    local delimiter="$1"
    local varName="$2"
    local dir="$3"
    if [[ -d "$dir" && "${!varName:+${delimiter}${!varName}${delimiter}}" \
          != *"${delimiter}${dir}${delimiter}"* ]]; then
        export "${varName}=${!varName:+${!varName}${delimiter}}${dir}"
    fi
}

addToSearchPath() {
    addToSearchPathWithCustomDelimiter ":" "$@"
}

# Return success if the specified file is a script (i.e. starts with
# "#!").
isScript() {
    local fn="$1"
    local fd
    local magic
    exec {fd}< "$fn"
    read -r -n 2 -u "$fd" magic
    exec {fd}<&-
    if [[ "$magic" =~ \#! ]]; then return 0; else return 1; fi
}

# printf unfortunately will print a trailing newline regardless
printLines() {
    (( "$#" > 0 )) || return 0
    printf '%s\n' "$@"
}

printWords() {
    (( "$#" > 0 )) || return 0
    printf '%s ' "$@"
}

######################################################################
# Generic builder helper functions.

# This function is useful for debugging broken Nix builds.  It dumps
# all environment variables to a file `env-vars' in the build
# directory.  If the build fails and the `-K' option is used, you can
# then go to the build directory and source in `env-vars' to reproduce
# the environment used for building.
dumpVars() {
    if [ "${noDumpEnvVars:-0}" != 1 ]; then
        # On darwin, install(1) cannot be called with /dev/stdin or fd from process substitution
        # so first we create the file and then write to it
        # See https://github.com/NixOS/nixpkgs/issues/335016
        {
            install -m 0600 /dev/null "$NIX_BUILD_TOP/env-vars" &&
            export 2>/dev/null >| "$NIX_BUILD_TOP/env-vars"
        } || true
    fi
}

# Utility function: echo the base name of the given path, with the
# prefix `HASH-' removed, if present.
stripHash() {
    local strippedName casematchOpt=0
    # On separate line for `set -e`
    strippedName="$(basename -- "$1")"
    shopt -q nocasematch && casematchOpt=1
    shopt -u nocasematch
    if [[ "$strippedName" =~ ^[a-z0-9]{32}- ]]; then
        echo "${strippedName:33}"
    else
        echo "$strippedName"
    fi
    if (( casematchOpt )); then shopt -s nocasematch; fi
}

showPhaseHeader() {
    local phase="$1"
    echo "Running phase: $phase"

    # The Nix structured logger allows derivations to update the phase as they're building,
    # which shows up in the terminal UI. See `handleJSONLogMessage` in the Nix source.
    if [[ -z ${NIX_LOG_FD-} ]]; then
        return
    fi
    printf "@nix { \"action\": \"setPhase\", \"phase\": \"%s\" }\n" "$phase" >&"$NIX_LOG_FD"
}

showPhaseFooter() {
    local phase="$1"
    local startTime="$2"
    local endTime="$3"
    local delta=$(( endTime - startTime ))
    (( delta < 30 )) && return

    local H=$((delta/3600))
    local M=$((delta%3600/60))
    local S=$((delta%60))
    echo -n "$phase completed in "
    (( H > 0 )) && echo -n "$H hours "
    (( M > 0 )) && echo -n "$M minutes "
    echo "$S seconds"
}
