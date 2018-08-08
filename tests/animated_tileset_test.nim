import ../src/nim_tiled
import os
import tables, typeinfo, base64

let map = loadTiledMap(getAppDir() & "/16x16Animated.tmx")

let tileset = map.tilesets[0]
for id, tile in tileset.tiles.pairs:
  echo tile
