import ../src/nim_tiled
import os
import tables, typeinfo, base64

let tiledMap = loadTiledMap getAppDir() & "/smile.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)

#echo "width: ", tiledMap.width
#echo "height: ", tiledMap.height

discard """#00d3a5"""

var i = open("output.txt", fmWrite)

for y in 0..<tiledMap.height:
  var line = newString(tiledMap.width)
  for x in 0..<tiledMap.width:
    let index = x + y * tiledMap.width
    for layer in tiledMap.layers:
      if layer.tiles[index] != 0:
        line[x] = '#'
      else:
        line[x] = '.'
  i.writeln(line)

i.close()
