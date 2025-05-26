# Corelib - fundamentals alternative to nixpkgs

This project is an experiment to replace the low-level Nixpkgs internals with
something more readable, more slim and more elegant while being equally
flexible compared to Nixpkgs' current use cases.

## Explanation

The idea behind a simpler Nixpkgs is to come up with a minimal set of
requirements for packages to be able to bootstrap them in a cross-compilation
context. This avoids complexity and leaves room for quality-of-life additions
outside of this repository.

Different repositories should be completely self-contained. A repository should
always know exactly what it needs and how to get it. This means that in this
alternative model, dependencies across repositories always follow a DAG
structure.

If the main mechanism to combine packages from multiple repositories was to use
an overlay, this would allow for cyclic dependencies (in edge cases if need
be). This opens up the door to trouble, wasted hours and weird interactions
between repositories. Corelib does not use overlays to combine packages.

Instead, packages that can be grouped together are explicitly grouped together
in a scope or *package set*. Instead of importing nixpkgs first and adding 3rd
party packages through an overlay, you can elaborate the 3rd party package set
immediately and let it handle its dependencies automatically. If you want to
use multiple package sets, you just elaborate the package sets and take what
you need from the result.

## Anatomy of a package set

Corelib leaves a lot of freedom when it comes to package set construction.
There are only 4 important requirements:

- It needs to be an *attribute set*
- If it exports packages, it needs a **`packages`** attribute
- If it has dependencies, it needs a **`dependencies`** attribute
- If it wants to inject pure, platform-independent functions into its package
  recipes, it needs a **`lib`** attribute

If these rules are followed, it's straightforward to then elaborate this
package set for a given build platform and run platform (see `default.nix`). An
example of a package set is:

```nix
{
  lib = self: {
    myAttrMapFunction = ...;
  };
  dependencies = {
    gcc-compilers = ...;
    openssl = ...;
  };
  packages = {
    openssh = import ./openssh.nix;
  };
}
```

**`lib`** is a fixpoint of pure functions/values, it is resolved when the
package set is elaborated (i.e. when the package recipes are evaluated). There
must be no platform-dependent functions in this attribute set. Consider it a
funnel to bundle external nix inputs together for use in package recipes.

**`dependencies`** is a set of package sets. This is a list of direct
dependencies this package set needs to properly evaluate its package recipes.
The names can be arbitrarily chosen and the dependency will be accessible under
the specified name when the package recipes get evaluated.

A **package recipe** or value from the `packages` attribute of the package set
can be either a function returning an attribute set or just an attribute set.
If it is a function, it is given the resolved attribute set of pure functions
defined in `lib` in the package set.

It can be elaborated, meaning that all the necessary contexts to produce a
cross-compiled build are enumerated and each dependency will be accessible
under the respective cross-compilation context currently active.

A package has two important attributes:
- **`function`** is the recipe that turns inputs into a derivation, a package,
  another function, ... it must act like a function and takes its arguments
  from `inputs`
- **`inputs`** gets the set of all packages in the current set and its
  dependencies grouped by name, `self` is the special name given to the package
  set itself. It also gets the platform triple `buildPlatform`, `runPlatform`
  and `targetPlatform` that specify the current cross-compilation context.

  In order to easily abstract over the different platforms when using
  dependencies, all packages are provided multiple times under different
  cross-compilation perspectives. If a package needs certain binaries only at
  buildtime, it can simple select that package using `package.onBuild`, (same
  for `onRun` and `onTarget`).

  If the package is as weird as GCC and requires a single compiler-target, it
  will define the `targetPlatform` attribute in its package recipe output and
  instead, the 6 attributes `onBuildForBuild`, `onBuildForRun`,
  `onBuildForTarget`, `onRunForRun`, `onRunForTarget` and `onTargetForTarget`
  will be provided.

This is an example of a package recipe:

```nix
# stage0-posix/kaem/default.nix

lib:
{
  function = {
    mescc-tools-extra,
    mescc-tools-boot2,
    mkMinimalPackage,
    ...
  }: let

    inherit (lib.std.strings) makeBinPath;
    inherit (mescc-tools-boot2.onRun) kaem-unwrapped;

  in mkMinimalPackage.onRun {
    name = "kaem";
    version = "1.6.0";
    drv = {
      builder = mescc-tools-boot2.onBuild.kaem-unwrapped;
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
      PATH = makeBinPath [ mescc-tools-extra.onBuild ];
      inherit
        kaem-unwrapped
        ;
    };
  };

  inputs = { pkgs, ... }: {
    inherit (pkgs.self)
      mescc-tools-boot2
      mescc-tools-extra
      mkMinimalPackage
      ;
  };
}
```

## Examples

A rough example of how this library can be used is provided under
- **`packages-set/set1`**: simple example showing the fixpoints used in corelib

- **`packages-set/stage0`**: a port of [oriansj's
  stage0](https://github.com/oriansj/stage0-posix) for `i686-linux`,
  `x86_64-linux`, `aarch64-linux`, `riscv64-linux` and `riscv32-linux`, fully
  independent from any other dependencies

- **`packages-set/gcc-bootstrap`**: WIP on getting to GCC from stage0,
  currently planned to go via GNU Mes, TinyCC and musl to GCC 14

`default.nix` shows the entrypoint to elaborating the previous package sets.
The result is just a set of packages that are ready to be realized.

All library code should be well-documented.

## License

This project is licensed under the MIT license. Any contribution will agree to
take on this license when merged into this project.

