import ../src/nim_tiled
import os
import tables, typeinfo, base64

let map = loadTiledMap(getAppDir() & "/8x8Csv.tmx")

doAssert(map.tilesets[0].imagePath == "tileset.png")
