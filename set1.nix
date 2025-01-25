let
  mkPackageSet = import ./mk-package-set.nix;

  set1 = mkPackageSet {
    # TODO: add self fixpoint for easy variants by overriding
    packages = self: {
      one = import ./set1/one.nix;
      two = import ./set1/two.nix;
    };
    lib = (lib: {
      fn1 = _: "_Testing1_";

      fn2 = _: "_Hi set1_ " + lib.std.fn3 + (lib.std2.fn1 {});

      fn3 = "_set1_ " + (lib.self.fn2 0) + (toString lib.self.deps);

      deps = builtins.attrNames lib;
    });
    dependencies = {
      std = set2;
      std2 = set3;
      std3 = set4;
    };
  };

  set4 = mkPackageSet {};

  set2 = mkPackageSet {
    lib = (lib: {
      fn1 = _: "_Testing2_";

      fn2 = _: "_Hi set2_ " + lib.std.fn3;

      fn3 = "_set2_ " + (lib.self.fn2 0) + (toString lib.self.deps);

      deps = builtins.attrNames lib;
    });
    dependencies = {
      std = set3;
    };
  };

  set3 = mkPackageSet {
    lib = (lib: {
      fn1 = _: "Testing3";

      fn2 = _: "_Hello from 3_ " + (lib.self.fn1 {});

      fn3 = "_Testing 3_" + (lib.self.fn2 0) + (toString lib.self.deps);

      deps = builtins.attrNames lib;
    });

  };
in
  set1
