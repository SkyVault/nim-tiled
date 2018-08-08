import ../src/nim_tiled
import os
import tables, typeinfo, base64

proc writeTiledToText(map: TiledMap): string=
  result = ""
  for y in 0..<map.height:
    var line = newString(map.width)
    for x in 0..<map.width:
      let index = x + y * map.width
      for layer in map.layers:
        if layer.tiles[index] != 0:
          line[x] = '#'
        else:
          line[x] = '.'
    result &= line & "\n"

let expected=""".##..##.
.##..##.
.##..##.
.##..##.
########
########
########
########
"""

doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8Csv.tmx")))
doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8Xml.tmx")))
doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8Base64Uncompressed.tmx")))
doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8Base64Gzip.tmx")))
doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8Base64Zlib.tmx")))
doAssert(expected == writeTiledToText(loadTiledMap(getAppDir() & "/8x8ZlibEmbededTilesheet.tmx")))

let map = loadTiledMap(getAppDir() & "/8x8ZlibEmbededTilesheet.tmx")

doAssert(fileExists map.tilesets[0].imagePath)
