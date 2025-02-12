# Corelib - fundamentals alternative to nixpkgs

This project is an experiment to replace the low-level Nixpkgs internals with
something more readable, more slim and more elegant while being equally flexible
compared to Nixpkgs' current use cases.

More information is provided in [the accompanying blog post](https://grizzlt.prose.sh/corelib-revolutionary-nixpkgs).

## Examples

A rough example of how this library can be used is provided under
- `packages/set1`: simple example showing use of the fixpoints
- `packages/stdenv`: A failing build of gnu's `hello` using the official
  boostrap files from Nixpkgs as `stdenv`. To instigate the motivation to
  rethink a lot of the machinery here.

The current bootstrapping is provided in `default.nix`. Changing the given
package sets to something else allows to bootstrap for this other thing.

All library code should be well-documented.

## License

This project is licensed under the MIT license. Any contribution will agree to
take on this license when merged into this project.

