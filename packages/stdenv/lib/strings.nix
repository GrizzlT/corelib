lib:

{
  /**
    Concatenate a list of strings with a separator between each element

    # Inputs

    `sep`
    : Separator to add between elements

    `list`
    : List of input strings

    # Type

    ```
    concatStringsSep :: string -> [string] -> string
    ```

    # Examples
    :::{.example}
    ## `lib.strings.concatStringsSep` usage example

    ```nix
    concatStringsSep "/" ["usr" "local" "bin"]
    => "usr/local/bin"
    ```

    :::
  */
  concatStringsSep = builtins.concatStringsSep;
}
