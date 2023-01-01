import ../src/nim_tiled
import unittest, print

suite "finite maps":
  test "finite csv | 30x20 map size | 16x16 tile size":
    let result = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx").orDefault
    echo result

  test "infinite csv | infinite map size | 16x 16x tile size":
    let result = loadTiledMap("tests/res/maps/infinite-csv.tmx").orDefault
    echo result