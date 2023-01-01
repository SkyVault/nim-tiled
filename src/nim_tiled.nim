import os, options, xmlparser, xmltree, streams, strformat, strutils, colors,
    print, sugar, sequtils, algorithm, tables

type
  LayerUID* = string
  TileUID* = int
  ObjectUID* = string

  Percent* = range[0..100]
  Milliseconds* = float

  Vec2 = tuple[x, y: float]
  Grid* = tuple[orientation: Orientation, width, height: float]

  Encoding* {.pure.} = enum
    none
    base64
    csv

  Compression* {.pure.} = enum
    none
    gzip
    zlib
    zstd

  Data* = object
    encoding*: Encoding = none
    compression*: Compression = none
    tiles*: seq[Tile]
    chunks*: seq[Chunk]

  Properties* = object

  Frame* = object
    tileid*: string
    duration*: Milliseconds

  Animation* = seq[Frame]

  Wangcolor* = object
    name, class, color*, tile*: string
    probability*: Percent

  Wangtile* = object
    tileid*, wangid*: string
    hflip*, vflip*, dflip*: bool

  Wangset* = object
    name, class, tile*: string
    properties*: Option[Properties]
    wangcolors*: seq[Wangcolor] # TODO: Assert max length of 255
    wangtiles*: seq[Wangtile]

  Wangsets* = seq[Wangset]

  Transformations* = object
    hflip*, vflip*, rotate*, preferuntransformed*: bool

  TilesetTile* = object
    id: string
    class: string

    probability*: Percent
    x*, y*, width*, height*: float
    properties*: Option[Properties]
    image*: Option[Image]
    animation*: Option[Animation]

  Image* = object
    format*: string
    # id: string - used by some versions of Tiled java. Depricated and unsupported
    source*: string
    trans*: string
    width*, height*: float

    data*: Option[Data]
    transformations*: Option[Transformations]

  RenderOrder* {.pure.} = enum
    rightDown
    rightUp
    leftDown
    leftUp

  Orientation* {.pure.} = enum
    orthogonal
    orthographic
    isometric
    staggered
    hexagonal

  ObjectAlignment* {.pure.} = enum
    unspecified
    topLeft
    top
    topRight
    center
    right
    bottomLeft
    bottom
    bottomRight

  TileRenderSize* {.pure.} = enum
    tile
    grid

  FillMode* {.pure.} = enum
    stretch
    preserveAspectFit

  Tileset* = object
    version, tiledversion: string
    firstGid: TileUID = 0

    source: string
    name, class: string

    tilewidth*, tileheight*: int
    spacing*, margin*: float
    tilecount*, columns*: int
    tileOffset*: Vec2
    objectAlignment*: ObjectAlignment
    tileRenderSize*: TileRenderSize
    fillMode*: FillMode
    image*: Option[Image]
    grid*: Option[Grid]
    properties*: Option[Properties]
    wangsets*: Option[Wangsets]

  Tile* = TileUID

  Chunk* = object
    x*, y*, width*, height*: float
    tiles*: seq[Tile]

  HAlignment* {.pure.} = enum
    left, center, right, justify

  VAlignment* {.pure.} = enum
    top, center, bottom

  ObjectKind* {.pure.} = enum
    obj
    ellipse
    point
    polygon
    polyline
    text

  Object = object
    id: int
    name, class: string
    x*, y*, width*, height*: float
    rotation*: float
    gid*: TileUID
    visible*: bool
    templateFile*: Option[string] # Links to a separate template file

    case kind*: ObjectKind
      of obj: discard
      of ellipse: discard
      of point: discard
      of polygon, polyline:
        points*: seq[Vec2]
      of text:
        fontfamily*: string
        pixelsize*: int
        wrap*, bold*, italic*, underline*, strikeout*, kerning*: bool
        color*: string
        halign*: HAlignment
        valign*: VAlignment

  LayerKind* = enum
    tiles
    objects
    image
    group

  Layer = object
    id: LayerUID
    name, class: string

    x*, y*: float
    width*, height*: int
    opacity*: float
    visible*: bool
    tintcolor*: string
    offsetx*, offsety*: float
    parallaxx*, parallaxy*: float
    properties*: Option[Properties]

    case kind*: LayerKind
      of tiles:
        data*: Data
      of objects:
        objects*: seq[Object]
      of image:
        repeatx, repeaty: bool
        image*: Option[Image]
      of group:
        layers*: seq[Layer]

  Axis = enum
    axisX
    axisY

  Map = object
    version, tiledversion, class: string
    orientation*: Orientation
    renderOrder*: RenderOrder
    compressionLevel* = -1
    width*, height*: int
    tilewidth*, tileheight*: int
    hexSideLength*: int
    staggerAxis*: Axis
    staggerIndex*: int
    parallaxOriginX*, parallaxOriginY*: int
    backgroundColor*: string
    nextLayerId*: LayerUID
    nextObjectid*: ObjectUID
    infinite*: bool

    properties*: Option[Properties]

    tilesets*: seq[Tileset]
    layers*: seq[Layer]

    firstGidToTilesetName: Table[TileUID, string]

proc id*(it: Layer|Object|TilesetTile): auto = it.id
proc name*(it: Layer|Object|Tileset|Wangset|Wangcolor): auto = it.name
proc class*(it: Layer|Object|Map|Tileset|TilesetTile|Wangset|Wangcolor): auto = it.class

proc version*(it: Tileset|Map): auto = it.version
proc tiledversion*(it: Tileset|Map): auto = it.tiledversion

proc firstGid*(it: Tileset): auto = it.firstGid
proc source*(it: Tileset): auto = it.source

## Utility functions

proc value[T](self: XmlNode, a: string, v: T): T =
  result = v

  when T is int:
    if self.attr(a) != "":
      return self.attr(a).parseInt()
  elif T is float:
    if self.attr(a) != "":
      return self.attr(a).parseFloat()
    else:
      return 0.0
  elif T is bool:
    if self.attr(a) == "" or self.attr(a) == "0":
      return false
    else:
      return true
  elif T is string:
    return self.attr(a)

proc tilesetForTileId*(map: Map, tileId: Tile): TileUID =
  result = 0

  # first sort tilesets by their firstGid
  # iterate highest to lowest
  # break when tileset.firstGid < tileId and return tileset.firstGid
  var tilesets = map.tilesets
  tilesets.sort(
    proc(a, b: Tileset): auto = cmp(a.firstGid, b.firstGid)
  )

  for i in 0..<len(tilesets):
    let ts = tilesets[i]

    if tileId >= ts.firstGid:
      result = ts.firstGid


## Builders

proc buildImage(node: XmlNode): Image =
  result.format = node.attr("format")
  result.trans = node.attr("trans")
  result.source = node.attr("source")
  result.width = value[float](node, "width", 0.0)
  result.height = value[float](node, "height", 0.0)

proc loadTilesetFields(tileset: var Tileset, node: XmlNode) =
  if tileset.firstGid == 0:
    tileset.firstGid =
      if node.attr("firstgid") == "": 1
      else: node.attr("firstgid").parseInt

  tileset.source = node.attr("source")
  tileset.name = node.attr("name")
  tileset.class = node.attr("class")
  tileset.tilewidth = value[int](node, "tilewidth", 0)
  tileset.tileheight = value[int](node, "tileheight", 0)
  tileset.spacing = value[float](node, "spacing", 0.0)
  tileset.margin = value[float](node, "margin", 0.0)
  tileset.tilecount = value[int](node, "tilecount", 0)
  tileset.columns = value[int](node, "columns", 0)
  # tileset.tileOffset = value[int](node, "tileoffset")
  tileset.objectAlignment =
    case node.attr("objectalignment"):
      of "unspecified": unspecified
      of "topLeft": topLeft
      of "top": top
      of "topRight": topRight
      of "center": center
      of "right": right
      of "bottomLeft": bottomLeft
      of "bottom": bottom
      of "bottomRight": bottomRight
      else: unspecified

  tileset.tileRenderSize =
    case node.attr("tileRenderSize")
      of "tile": tile
      of "grid": grid
      else: tile

  tileset.fillMode =
    case node.attr("fillMode")
      of "stretch": stretch
      of "preserveAspectFit": preserveAspectFit
      else: stretch

  for child in node:
    case child.tag
      of "image":
        tileset.image = some buildImage(child)
      else:
        echo "Unhandled tileset child tag: " & child.tag

  # TODO: grid

  # TODO: properties

  # TODO: wangsets

proc buildTileset(node: XmlNode, path: string, loadsource = true): Tileset =
  result.firstGid =
    if node.attr("firstgid") == "": 1
    else: node.attr("firstgid").parseInt

  result.source = node.attr("source")

  if result.source != "" and loadsource:
    let tilesetNode = readFile(path.parentDir().joinPath(
        result.source)).newStringStream().parseXml()
    result.loadTilesetFields(tilesetNode)
  else:
    result.loadTilesetFields(node)

proc buildProperties(props: XmlNode): Properties =
  discard

proc buildTiles(csv: string): seq[Tile] =
  csv.split({',', '\n'}).filterIt(it != "").map(it => Tile(parseInt(it)))

proc buildChunk(node: XmlNode, encoding: Encoding,
    compression: Compression): Chunk =
  result.x = node.attr("x").parseFloat
  result.y = node.attr("y").parseFloat
  result.width = node.attr("width").parseFloat
  result.height = node.attr("height").parseFloat
  result.tiles = node.innerText.buildTiles()

proc buildData(data: XmlNode): Data =
  case data.attr("encoding")
    of "base64": result.encoding = base64
    of "csv": result.encoding = csv
    else:
      let en = data.attr("encoding")
      echo &"Unexpected encoding '{en}' for data."

  case data.attr("compression"):
    of "gzip": result.compression = gzip
    of "zlib": result.compression = zlib
    of "zstd": result.compression = zstd
    else: discard

  # TODO: Handle base64 encoding
  var hasChunk = false

  for node in data:
    if node.kind == xnElement:
      case node.tag
        of "chunk":
          hasChunk = true
          result.chunks.add buildChunk(node, result.encoding,
              result.compression)
        of "tile":
          echo "WIP: node 'tile' not handled for data."
          discard
    elif node.kind == xnText:
      result.tiles = node.innerText.buildTiles()

proc buildLayer(node: XmlNode): Layer =
  result.kind = tiles
  result.id = node.attr("id")
  result.name = node.attr("name")
  result.class = node.attr("class")
  result.x = value[float](node, "x", 0.0)
  result.y = value[float](node, "y", 0.0)
  result.width = value[int](node, "width", 0)
  result.height = value[int](node, "height", 0)
  result.visible = if node.attr("visible") == "": true else: value[bool](node,
      "visible", true)
  result.tintcolor = node.attr("tintcolor")
  result.offsetx = value[float](node, "offsetx", 0.0)
  result.offsety = value[float](node, "offsety", 0.0)
  result.parallaxx = value[float](node, "parallaxx", 0.0)
  result.parallaxy = value[float](node, "parallaxy", 0.0)

  for subNode in node:
    case subNode.tag
      of "data":
        result.data = buildData(subNode)
      of "properties":
        result.properties = buildProperties(subNode).some
      else:
        echo &"Unexpected child tag for layer: {subNode.tag}"

proc buildTilemap(node: XmlNode, path: string): Map =
  result = Map()
  result.version = node.attr "version"
  result.tiledVersion = node.attr "tiledversion"
  result.class = node.attr "class"

  result.infinite = node.attr("infinite") == "1"

  result.width = node.attr("width").parseInt
  result.height = node.attr("width").parseInt
  result.tilewidth = node.attr("tilewidth").parseInt
  result.tileheight = node.attr("tileheight").parseInt

  result.orientation =
    case node.attr("orientation"):
      of "orthogonal": orthogonal
      of "orthographic": orthographic
      of "isometric": isometric
      of "staggered": staggered
      of "hexagonal": hexagonal
      else: orthogonal

  result.renderOrder =
    case node.attr("renderorder"):
      of "right-down": rightDown
      of "right-up": leftDown
      of "left-up": rightUp
      of "left-down": leftUp
      else: rightDown

  # TODO: Compression level

  result.nextLayerId = node.attr("nextlayerid")
  result.nextObjectid = node.attr("nextobjectid")

  result.hexSideLength = value[int](node, "hexsidelength", 0)
  result.staggerIndex = value[int](node, "staggerindex", 0)

  result.parallaxOriginX = value[int](node, "parallaxoriginx", 0)
  result.parallaxOriginY = value[int](node, "parallaxoriginy", 0)
  result.backgroundColor = value[string](node, "backgroundcolor", "")

  # TODO: load custom map properties

  for item in node:
    case item.tag:
      of "tileset": result.tilesets.add buildTileset(item, path)
      of "layer": result.layers.add buildLayer(item)
      of "properties": result.properties = buildProperties(item).some
      else: echo "Unhandled tag: ", item.tag

  result.firstGidToTilesetName = initTable[TileUID, string]()

  for tileset in result.tilesets:
    result.firstGidToTilesetName[tileset.firstGid] = tileset.name

proc getTilesetNameGivenFirstGid*(map: Map, uid: TileUID): string =
  map.firstGidToTilesetName[uid]

type
  LoadResultKind = enum
    tiledOk
    tiledError

  LoadErrorKind = enum
    tiledErrorFileNotFound

  LoadResult = object
    case kind: LoadResultKind
      of tiledOk:
        tiledMap*: Map
      of tiledError:
        errorMessage*: string

proc kind*(res: LoadResult): LoadResultKind =
  res.kind

func isOk*(res: LoadResult): bool = res.kind == tiledOk

proc orDefault*(res: LoadResult): Map =
  if res.kind == tiledOk:
    result = res.tiledMap
  else:
    echo res.errorMessage

proc errorResult(kind: LoadErrorKind, message: string): LoadResult =
  result = LoadResult(kind: tiledError, errorMessage: message)

proc loadTiledMap*(path: string): LoadResult =
  if not fileExists(path):
    return errorResult(tiledErrorFileNotFound, "File does not exist.")

  result = LoadResult(
    kind: tiledOk,
    tiledMap: buildTilemap(
      readFile(path).newStringStream().parseXml(),
      path
    )
  )
