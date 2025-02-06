lib: {
  composeExtensions = f: g: self: super: let
    fApplied = f self super;
    super' = super // fApplied;
  in fApplied // g self super';

  fix = f: let x = f x; in x;

  extends = overlay: f: (self: let
    super = f self;
  in super // overlay self super);
}
