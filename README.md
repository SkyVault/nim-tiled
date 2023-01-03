# Nim Tiled
[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)

## Introduction

A tiled map loader for the [Nim](nim-lang.org) programming language. The Tiled map editor can be found [here](https://www.mapeditor.org/).
Documentation for the tiled file format can be found [here](https://doc.mapeditor.org/en/stable/).

Example

```nim
echo "Loaded the tiled map: ", loadTiledMap("tilemap.tmx").orDefault
```

Example with error handling

```nim
let res = loadTiledMap("tilemap.tmx")

if res.isOk:
  echo "Loaded the tiled map: ", res.tiledMap
```

## Documentation

​	Generate documentation by running the `nimble docs` command

## Example using [Windy](https://github.com/treeform/windy), [Pixie](https://github.com/Vladar4/sdl2_nim) and [Boxy](https://github.com/treeform/boxy)

Infinite Tilemap

```nim
```
