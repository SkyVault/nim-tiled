import ../src/nim_tiled
import unittest, print, options

suite "finite maps":
  test "finite csv | 30x20 map size | 16x16 tile size":
    let result = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx").orDefault
    let layer = result.layers[0]
    check result.layers[0].tileAt(3, 3) == TileUID(2)

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
    check props[0].kind == boolProp
    check props[0].kind == boolProp and props[0].boolean == true

    check props[1].kind == colorProp
    check props[1].kind == colorProp and props[1].color == "#ffff557f"

    check props[2].kind == fileProp
    check props[2].kind == fileProp and props[2].path == "finite-csv-30x20.tmx"

    check props[3].kind == floatProp
    check props[3].kind == floatProp and props[3].number == 3.1415926

    check props[4].kind == objectProp
    check props[4].kind == objectProp and props[4].objectValue == "0"

    check props[5].kind == stringProp
    check props[5].kind == stringProp and props[5].str == "This is a string"

  test "objects":
    let result = loadTiledMap("tests/res/maps/objects.tmx").orDefault