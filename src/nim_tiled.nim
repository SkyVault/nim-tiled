import os, options

type
  LayerUID = distinct int
  TileUID = distinct int
  ObjectUID = distinct int

  Percent = range[0..100]
  Milliseconds = float

  Vec2 = tuple[x, y: float]
  Grid = tuple[orientation: Orientation, width, height: float]

  Encoding {.pure.} = enum
    none
    base64
    csv

  Compression {.pure.} = enum
    gzip
    zlib
    zstd

  Data = object
    encoding: Encoding
    compression: Compression
    tiles: seq[Tile]
    chunks: seq[Chunk]

  Properties = object

  Frame = object
    tileid: string
    duration: Milliseconds

  Animation = seq[Frame]

  Wangcolor = object
    name, class, color, tile: string
    probability: Percent

  Wangtile = object
    tileid, wangid: string
    hflip, vflip, dflip: bool

  Wangset = object
    name, class, tile: string
    properties: Option[Properties]
    wangcolors: seq[Wangcolor] # TODO: Assert max length of 255
    wangtiles: seq[Wangtile]

  Wangsets = seq[Wangset]

  Transformations = object
    hflip, vflip, rotate, preferuntransformed: bool

  TilesetTile = object
    id: string
    class: string
    probability: Percent
    x, y, width, height: float
    properties: Option[Properties]
    image: Option[Image]
    animation: Option[Animation]

  Image = object
    format: string
    # id: string - used by some versions of Tiled java. Depricated and unsupported
    source: string
    trans: string
    width, height: float

    data: Option[Data]
    transformations: Option[Transformations]

  RenderOrder {.pure.} = enum
    rightDown
    rightUp
    leftDown
    leftUp

  Orientation {.pure.} = enum
    orthogonal
    isometric
    staggered
    hexagonal

  ObjectAlignment {.pure.} = enum
    unspecified
    topLeft
    top
    topRight
    center
    right
    bottomLeft
    bottom
    bottomRight

  TileRenderSize {.pure.} = enum
    tile
    grid

  FillMode {.pure.} = enum
    stretch
    preserveAspectFit

  Tileset = object
    firstGid: TileUID
    source: string
    name, class: string
    tilewidth, tileheight: int
    spacing, margin: float
    tilecount, columns: int
    tileOffset: Vec2
    objectAlignment: ObjectAlignment
    tileRenderSize: TileRenderSize
    fillMode: FillMode
    image: Option[Image]
    grid: Option[Grid]
    properties: Option[Properties]
    wangsets: Option[Wangsets]

  Tile = TileUID

  Chunk = object
    x, y, width, height: float
    tiles: seq[Tile]

  HAlignment {.pure.} = enum
    left, center, right, justify
  
  VAlignment {.pure.} = enum
    top, center, bottom

  ObjectKind {.pure.} = enum
    obj
    ellipse
    point
    polygon
    polyline
    text
  
  Object = object
    id: int
    name, class: string
    x, y, width, height: float
    rotation: float
    gid: TileUID
    visible: bool
    templateFile: Option[string] # Links to a separate template file

    case kind: ObjectKind
      of obj: discard
      of ellipse: discard
      of point: discard
      of polygon, polyline:
        points: seq[Vec2]
      of text:
        fontfamily: string
        pixelsize: int
        wrap, bold, italic, underline, strikeout, kerning: bool
        color: string
        halign: HAlignment
        valign: VAlignment

  LayerKind {.pure.} = enum
    tiles
    objects
    image
    group

  Layer = object
    id: LayerUID
    name, class: string
    x, y, width, height: float
    opacity: float
    visible: bool
    tintcolor: string
    offsetx, offsety: float
    parallaxx, parallaxy: float
    properties: Option[Properties]
    data: Option[Data]

    case kind: LayerKind
      of tiles:
        chunks: seq[Chunk]
        tiles: seq[Tile]
      of objects:
        objects: seq[Object]
      of image:
        repeatx, repeaty: bool
        image: Option[Image]
      of group:
        layers: seq[Layer]

  Axis = enum
    axisX
    axisY

  Map = object
    version, tiledversion, class: string
    orientation: Orientation
    renderOrder: RenderOrder
    compressionLevel: int
    width, height: int
    tilewidth, tileheight: int
    hexsidelength: int
    staggeraxis: Axis
    staggerindex: int
    parallaxOriginX, parallaxOriginY: int
    backgroundColor: string
    nextLayerId: LayerUID
    nextObjectid: ObjectUID
    infinite: bool

    tilesets: seq[Tileset]
    layers: seq[Layer]

  LoadResultKind = enum
    tiledOk
    tiledError

  LoadErrorKind = enum
    tiledErrorFileNotFound

  LoadResult = object
    case kind: LoadResultKind
      of tiledOk:
        tiledMap: Map
      of tiledError:
        errorMessage: string

proc errorResult(kind: LoadErrorKind, message: string): LoadResult =
  result = LoadResult(kind: tiledError, errorMessage: message)

proc loadTiledMap* (path: string): LoadResult =
  if not fileExists(path):
    return errorResult(tiledErrorFileNotFound, "File does not exist.")