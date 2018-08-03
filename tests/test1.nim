import ../src/nim_tiled
import os

let tiledMap = loadTiledMap getAppDir() & "/testMap.tmx"

doAssert(tiledMap.tilewidth == 16)
doAssert(tiledMap.tileheight == 16)
