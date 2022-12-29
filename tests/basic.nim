import ../src/nim_tiled
import unittest, print

suite "basic tile map loading":
  test "basic csv | 10x10 map size | 16x16 tile size":
    let result = loadTiledMap("tests/res/maps/basic.tmx")

    print result
