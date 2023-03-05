import ../src/nim_tiled, tables
import unittest, options

suite "finite maps":
  test "basic":
    let res = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx")

    if res.isOk:
      echo "Loaded the tiled map: ", res.tiledMap

  test "finite csv | 30x20 map size | 16x16 tile size":
    let result = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx").orDefault
    let layer = result.layers[0]
    check result.layers[0].tileAt(3, 3) == Tile(2)

  test "infinite csv | infinite map size | 16x 16x tile size":
    let result = loadTiledMap("tests/res/maps/infinite-csv.tmx").orDefault

  test "infinite csv | multiple tilesets":
    let result = loadTiledMap("tests/res/maps/infinite-csv-multiple-tilesets.tmx").orDefault

    check tilesetForTileId(result, Tile(10)) == Tile(1)
    check tilesetForTileId(result, Tile(300)) == Tile(257)

    check result.getTilesetNameGivenFirstGid(Tile(1)) == "tileset"
    check result.getTilesetNameGivenFirstGid(tilesetForTileId(result, Tile(
        300))) == "tileset2"

  test "properties":
    let result = loadTiledMap("tests/res/maps/properties.tmx").orDefault

    let props = result.properties
    check props["boolean"].kind == boolProp
    check props["boolean"].kind == boolProp and props["boolean"].boolean == true

    check props["color property"].kind == colorProp
    check props["color property"].kind == colorProp and props["color property"].color == "#ffff557f"

    check props["file path"].kind == fileProp
    check props["file path"].kind == fileProp and props["file path"].path == "finite-csv-30x20.tmx"

    check props["float test"].kind == floatProp
    check props["float test"].kind == floatProp and props["float test"].number == 3.1415926

    check props["object test"].kind == objectProp
    check props["object test"].kind == objectProp and props["object test"].objectValue == "0"

    check props["string test"].kind == stringProp
    check props["string test"].kind == stringProp and props["string test"].str == "This is a string"

  test "objects":
    discard loadTiledMap("tests/res/maps/objects.tmx").orDefault

  test "animations":
    discard loadTiledMap("tests/res/maps/animated.tmx").orDefault

  test "wangtiles":
    discard loadTiledMap("tests/res/maps/wangsets.tmx").orDefault

suite "encodings":
  test "we can load base64 encoded tilemaps":
    let a = loadTiledMap("tests/res/maps/base64-encoded-no-compression.tmx").orDefault
    let b = loadTiledMap("tests/res/maps/reference.tmx").orDefault

    for i in 0..<9:
      check a.layers[0].tileAt(i) == b.layers[0].tileAt(i)

  test "bigger test":
    echo loadTiledMap("tests/res/maps/TestArea.tmx").orDefault

suite "compression":
  test "we can load zlib compressed data":
    let a = loadTiledMap("tests/res/maps/zlib-compression.tmx").orDefault
    let b = loadTiledMap("tests/res/maps/reference.tmx").orDefault

    for i in 0..<9:
      check a.layers[0].tileAt(i) == b.layers[0].tileAt(i)
