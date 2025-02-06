/*
  Example package making use of [`mkPackage`].
*/
core:
{
  function = { mkPackage, ... }: (mkPackage (self: {
    public = { name = "test-package"; };
  })).addLayer (self: super: {
    public = super.public // { name = super.public.name + "-1"; };
  });

  dep-defaults = { lib, ... }: {
    inherit (lib.self) mkPackage;
  };
}
