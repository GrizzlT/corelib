{ pkgs }:
{
  value = pkgs.self.two.value + 2;
}
