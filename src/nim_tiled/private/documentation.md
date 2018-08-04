# Nim Tiled Documentation

[Skip to examples](#examples)

## Types

​	RGBA value for color properties, each value is a range between 0.0 - 1.0

```nim
TiledColor = (float, float, float, float)
```

​	The sprite region for each tile in the image

```nim
TiledRegion = object
	x, y, width, height: int
```

## Examples

```nim
# SDL2 example
let map = loadTiledMap("tilemap.tmx")
```

