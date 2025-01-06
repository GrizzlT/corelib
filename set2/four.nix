{ pkgs }:
{
  value = pkgs.self.two.value + " plus 1";

  depValue = pkgs.pkgs1.one.value;
}
