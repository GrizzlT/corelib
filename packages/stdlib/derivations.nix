lib:
let

  inherit (lib.self.fixed-points)
    composeExtensions
    extends
    fix
    ;

in {

  /**
    ## Construct an encapsulated fixpoint.

    The resulting fixpoint attribute set is equipped with an extension function
    `addLayer`. This function extends the fixpoint with an overlay.
    All fixpoint attributes are exported in `internals` in the final result. Any
    attribute in `public` is exported directly.

    ### Example
    The following:
    ```nix
      mkEncapsulate (self: {
        public.name = "${self.pname}-${self.version}";
        pname = "package";
        version = "0.1.0";
      })
    ```
    will result in
    ```nix
      {
        addLayer = <function>;
        internals = {
          pname = "package";
          version = "0.1.0";
          public = { # repeated final attribute set };
        };
        name = "package-0.1.0"
      }
    ```
    = Performance

    The `addLayer` lives outside of the fixpoint. This means multiple layers are
    first merged into one by means of `composeExtensions`. I believe this reuses
    "intermediate results" in between overlay layers. The fixpoint is only
    calculated when other attributes are evaluated. The main consequence of this
    performance measure currently is the inability to use `addLayer` inside of
    the fixpoint. This could be added in the future but awaits a valid use case.

  */
  mkEncapsulate = init: let
    build = self: init self;

    withExtraAttrs = prevLayer: raw: let
      result = fix (extends prevLayer raw);
    in result.public // {
      addLayer = layer: withExtraAttrs (composeExtensions prevLayer layer) raw;
    };
  in withExtraAttrs (self: super: {
    public = super.public or {} // { internals = self; };
  }) build;

}
