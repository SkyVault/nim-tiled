import ../src/nim_tiled
import os
import tables, typeinfo

let tiledMap = loadTiledMap getAppDir() & "/smile.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)

#echo "width: ", tiledMap.width
#echo "height: ", tiledMap.height

discard """#00d3a5"""

for objectGroup in tiledMap.objectGroups:
  for obj in objectGroup.objects:
    for key, val in obj.properties.pairs:
      if val.valueType == tvInt:
        echo val.valueInt
