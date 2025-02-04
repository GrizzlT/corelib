lib:

{
  fn1 = _: "Testing";

  fn2 = _: "Hello " + (lib.self.fn1 {});

  fn3 = "Testing " + (lib.self.fn2 0);
}

