let
  set1 = {
    packages = {
      one = import ./one.nix;
      two = import ./two.nix;
    };
    lib = (lib: {
      fn1 = _: "_Testing1_";

      fn2 = "_set1_ " + (lib.fn1 0);

      deps = builtins.attrNames lib;
    });
    dependencies = {
      std = set2;
      std2 = set3;
      std3 = set4;
    };
  };

  set2 = {
    lib = (lib: {
      fn1 = _: "_Testing2_";

      fn2 = "_set2_ " + (lib.fn1 0);

      deps = builtins.attrNames lib;
    });
    dependencies = {
      std = set3;
    };
  };

  set3 = {
    lib = (lib: {
      fn1 = _: "Testing3";

      fn2 = _: "_Hello from 3_ " + (lib.fn1 {});

      fn3 = "_Testing 3_" + (lib.fn2 0);
    });
  };

  set4 = {};
in
  set1
