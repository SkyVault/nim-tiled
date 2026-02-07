import ../src/nim_tiled, tables
import unittest

suite "finite maps":
  test "basic":
    try:
      let res = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx")
      echo "Loaded the tiled map: ", res.name
    except TiledError as e:
      echo "Failed to load map: ", e.msg
      check false

  test "finite csv | 30x20 map size | 16x16 tile size":
    let result = loadTiledMap("tests/res/maps/finite-csv-30x20.tmx")
    let layer = result.layers[0]
    check result.layers[0].tileAt(3, 3) == Tile(2)

  test "infinite csv | infinite map size | 16x 16x tile size":
    let result = loadTiledMap("tests/res/maps/infinite-csv.tmx")
    check result.infinite == true

  test "infinite csv | multiple tilesets":
    let result = loadTiledMap("tests/res/maps/infinite-csv-multiple-tilesets.tmx")

    check tilesetForTileId(result, Tile(10)) == Tile(1)
    check tilesetForTileId(result, Tile(300)) == Tile(257)

    check result.getTilesetNameGivenFirstGid(Tile(1)) == "tileset"
    check result.getTilesetNameGivenFirstGid(tilesetForTileId(result, Tile(
        300))) == "tileset2"

  test "properties":
    let result = loadTiledMap("tests/res/maps/properties.tmx")

    let props = result.properties
    check props["boolean"].kind == BoolProp
    check props["boolean"].kind == BoolProp and props["boolean"].boolean == true

    check props["color property"].kind == ColorProp
    check props["color property"].kind == ColorProp and props["color property"].color == "#ffff557f"

    check props["file path"].kind == FileProp
    check props["file path"].kind == FileProp and props["file path"].path == "finite-csv-30x20.tmx"

    check props["float test"].kind == FloatProp
    check props["float test"].kind == FloatProp and props["float test"].number == 3.1415926

    check props["object test"].kind == ObjectProp
    check props["object test"].kind == ObjectProp and props["object test"].objectValue == "0"

    check props["string test"].kind == StringProp
    check props["string test"].kind == StringProp and props["string test"].str == "This is a string"

  test "objects":
    discard loadTiledMap("tests/res/maps/objects.tmx")

  test "animations":
    discard loadTiledMap("tests/res/maps/animated.tmx")

  test "wangtiles":
    discard loadTiledMap("tests/res/maps/wangsets.tmx")

suite "encodings":
  test "we can load base64 encoded tilemaps":
    let a = loadTiledMap("tests/res/maps/base64-encoded-no-compression.tmx")
    let b = loadTiledMap("tests/res/maps/reference.tmx")

    for i in 0..<9:
      check a.layers[0].tileAt(i) == b.layers[0].tileAt(i)

  test "bigger test":
    let result = loadTiledMap("tests/res/maps/TestArea.tmx")
    echo "Loaded TestArea: ", result.name

suite "compression":
  test "we can load zlib compressed data":
    let a = loadTiledMap("tests/res/maps/zlib-compression.tmx")
    let b = loadTiledMap("tests/res/maps/reference.tmx")

    for i in 0..<9:
      check a.layers[0].tileAt(i) == b.layers[0].tileAt(i)

suite "CapitalCity":
  test "can load CapitalCity.tmx":
    let result = loadTiledMap("tests/res/CapitalCity.tmx")
    check result.name == "CapitalCity"
    check result.infinite == true
    check result.width == 30
    check result.height == 20
    check result.tilewidth == 32
    check result.tileheight == 32

  test "CapitalCity has correct number of layers":
    let result = loadTiledMap("tests/res/CapitalCity.tmx")
    check result.layers.len == 2
    check result.layers[0].name == "Tile Layer 1"
    check result.layers[1].name == "Tile Layer 2"

  test "CapitalCity has chunks":
    let result = loadTiledMap("tests/res/CapitalCity.tmx")
    check result.layers[0].kind == Tiles
    check result.layers[0].data.chunks.len == 4

    # Check first chunk dimensions
    let chunk0 = result.layers[0].data.chunks[0]
    check chunk0.x == -16.0
    check chunk0.y == -16.0
    check chunk0.width == 16
    check chunk0.height == 16

  test "CapitalCity tileset reference":
    let result = loadTiledMap("tests/res/CapitalCity.tmx")
    check result.tilesets.len == 1
    check result.tilesets[0].firstGid == 1
    check result.tilesets[0].source == "../tilesheets/tilesheet.tsx"
