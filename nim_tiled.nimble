# Package

version       = "2.0.1"
author        = "SkyVault, enthus1ast, exelotl"
description   = "Tiled map loader for the Nim programming language"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 0.18.0"
requires "zippy"

task docs, "Compiles documentation":
  exec "nim doc --project --index:on --outdir:htmldocs src/nim_tiled.nim"