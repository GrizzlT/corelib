{ fetchurl, stage1, ... }:
let

in {
  inherit musl binutils;
  inherit muslSrc binutilsSrc;
}
