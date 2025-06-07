lib:
{
  pushDownPlatforms = attrs: let
    packages = lib.std.attrsets.foldlAttrs
      (acc: _: value: acc // (builtins.mapAttrs (_: _: 0) value))
      {}
      attrs;
  in builtins.mapAttrs
    (name: _: lib.std.attrsets.foldlAttrs
      (acc: flavor: value: acc // (if value ? ${name} then { ${flavor} = value.${name}; } else {}))
      {}
      attrs
    )
    packages;
}
