# Nim Tiled
## Introduction

Tiled map loader for the [Nim](nim-lang.org) programming language. The Tiled editor can be found [here](https://www.mapeditor.org/).

```nim
let map = loadTiledMap("tilemap.tmx")
doAssert(map.width == 128)
```

## Documentation

​	Generate documentation by running the doc2 command

```bash
nimble doc2 src/nim_tiled.nim
```

## Example using SDL2

