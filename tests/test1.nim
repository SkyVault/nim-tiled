import ../src/nim_tiled
import os
import tables, typeinfo

let tiledMap = loadTiledMap getAppDir() & "/smile.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)

#echo "width: ", tiledMap.width
#echo "height: ", tiledMap.height

discard """#00d3a5"""

