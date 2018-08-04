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

## Example using [SDL2](https://github.com/Vladar4/sdl2_nim/blob/master/examples/ex201_textures.nim)

```nim
import nim_tiled, sdl2/sdl, sdl2/sdl_image as img

let map = loadTiledMap("8x8Base64Zlib.tmx")

doAssert(sdl.init(sdl.InitVideo) == 0)
doAssert(img.init(img.InitPng) != 0)

var window = sdl.createWindow("", sdl.WindowPosUndefined, sdl.WindowPosUndefined, 800, 600, 0)
var renderer = sdl.createRenderer(window, -1, sdl.RendererAccelerated or sdl.RendererPresentVsync)
var e: sdl.Event

var tileset = map.tilesets[0]
var texture = renderer.loadTexture("tileset.png")

var running = true
while running:
  while sdl.pollEvent(addr(e)) != 0:
    if e.kind == sdl.Quit: running = false

  for layer in map.layers:
    for y in 0..<layer.height:
      for x in 0..<layer.width:
        let index = x + y * layer.width
        let gid = layer.tiles[index]

        if gid != 0:
          let region = tileset.regions[gid - 1]

          var sregion = sdl.Rect(x: region.x, y: region.y, w: region.width, h: region.height)
          var dregion = sdl.Rect(x: x * map.tilewidth, y: y * map.tileheight, w: map.tilewidth, h: map.tileheight)

          discard renderer.renderCopy(
            texture,
            addr(sregion),
            addr(dregion)
          )
  renderer.renderPresent()
```

