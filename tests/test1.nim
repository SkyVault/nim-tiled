import ../src/nim_tiled
import os
import tables, typeinfo, base64

let tiledMap = loadTiledMap getAppDir() & "/smile.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)

#echo "width: ", tiledMap.width
#echo "height: ", tiledMap.height

discard """#00d3a5"""

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

writeFile("output.txt", writeTiledToText tiledMap)

let text = writeTiledToText(loadTiledMap(getAppDir() & "/8x8.tmx"))
let expected="""........
..#..#..
..#..#..
..#..#..
#......#
#......#
.#....#.
..####..
"""
echo text
echo expected
doAssert(text == expected)
