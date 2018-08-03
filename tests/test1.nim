import ../src/nim_tiled
import os

let tiledMap = loadTiledMap getAppDir() & "/smile.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)

echo "width: ", tiledMap.width
echo "height: ", tiledMap.height

for objectGroup in tiledMap.objectGroups:
  for obj in objectGroup.objects:
    echo obj
