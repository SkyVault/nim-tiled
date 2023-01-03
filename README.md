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

### Infinite Tilemap demo

[Infinite Tilemap demo](https://github.com/SkyVault/nim-tiled-demo)

```nim
import windy, boxy, pixie, opengl, options, os, nim_tiled

when isMainModule:
  var window = newWindow("Tiled Map Demo!", ivec2(640, 640))
  window.makeContextCurrent()
  loadExtensions()

  var bxy = newBoxy()

  let
    tiledMap = loadTiledMap("res/TestArea.tmx").orDefault
    tileset = tiledMap.tilesets[0]
    tilesetImage = readImage("res".joinPath tileset.image.get().source)

  proc renderTile(key: string, gid: Tile) =
    if not bxy.contains(key):
      let
        img = newImage(tileset.tilewidth, tileset.tileheight)
        ctx = newContext(img)
        tw = tileset.tilewidth.float
        th = tileset.tileheight.float
        rx = (gid mod tileset.columns).float * tw
        ry = (gid.float / tileset.columns.float).int.float * th

      ctx.drawImage(tilesetImage, rect(vec2(rx.float, ry.float), vec2(tw, th)),
          rect(vec2(), vec2(tw, th)))

      bxy.addImage(key, img)

  while not window.closeRequested:
    glClear(GL_COLOR_BUFFER_BIT)
    bxy.beginFrame(window.size)

    for layer in tiledMap.layers:
      if layer.kind == tiles:
        for chunk in layer.data.chunks:
          for x in 0..<chunk.width.int:
            for y in 0..<chunk.height.int:
              let
                tw = tileset.tilewidth.float
                th = tileset.tileheight.float
                gid = chunk.tiles[x + y * chunk.width.int]
                key = "tile-" & $gid

              if gid > 0:
                renderTile(key, gid - 1)
                bxy.drawImage(key, pos = vec2(200.0, 128.0) + vec2(((
                    chunk.x.int + x) * tw.int).float, ((chunk.y.int + y) *
                        th.int).float))

    bxy.endFrame()
    window.swapBuffers()
    pollEvents()
```
