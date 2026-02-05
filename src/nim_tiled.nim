import os, options, xmlparser, xmltree, streams, strformat, strutils, colors,
    sugar, sequtils, algorithm, tables, base64, zippy

type
  LayerGid* = string
  TileGid* = int
  ObjectGid* = string

  Percent* = range[0..100]
  Milliseconds* = int

  Vec2 = tuple[x, y: float]
  Grid* = object
    orientation: Orientation
    width, height: float

  Encoding* = enum
    NoEncoding
    Base64
    Csv

  Compression* = enum
    NoCompression
    Gzip
    Zlib
    Zstd

  Data* = object
    encoding*: Encoding = NoEncoding
    compression*: Compression = NoCompression
    tiles*: seq[Tile]
    chunks*: seq[Chunk]

  PropKind* = enum
    BoolProp
    ColorProp
    FileProp
    FloatProp
    ObjectProp
    StringProp

  Prop* = object
    case kind*: PropKind
      of BoolProp: boolean*: bool
      of ColorProp: color*: string
      of FileProp: path*: string
      of FloatProp: number*: float
      of ObjectProp: objectValue*: string
      of StringProp: str*: string

  Properties* = Table[string, Prop]

  Frame* = object
    tileid*: Tile
    duration*: Milliseconds

  Animation* = seq[Frame]

  Wangcolor* = object
    name, class, color*: string
    tile*: Tile
    probability*: Percent
    properties*: Properties

  Wangtile* = object
    tileid*: TileGid
    # TODO: Do we want to support the old 32-bit unsigned integer version of this value?
    wangid*: seq[TileGid]
    hflip*, vflip*, dflip*: bool

  Wangset* = object
    name, class: string
    tile*: Tile
    properties*: Properties
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
    properties*: Properties
    image*: Option[Image]
    animation*: Option[Animation]
    objectGroup*: Option[Layer]
    tileoffset*: Vec2

  Image* = object
    format*: string
    # id: string - used by some versions of Tiled java. Depricated and unsupported
    source*: string
    trans*: string
    width*, height*: float

    data*: Option[Data]
    transformations*: Option[Transformations]

  RenderOrder* = enum
    RightDown
    RightUp
    LeftDown
    LeftUp

  Orientation* = enum
    Orthogonal
    Orthographic
    Isometric
    Staggered
    Hexagonal

  ObjectAlignment* = enum
    Unspecified
    TopLeft
    Top
    TopRight
    Center
    Right
    BottomLeft
    Bottom
    BottomRight

  TileRenderSize* = enum
    TileSize
    GridSize

  FillMode* = enum
    Stretch
    PreserveAspectFit

  Tileset* = object
    version, tiledversion: string
    firstGid: TileGid = 0

    source: string
    name, class: string

    tilewidth*, tileheight*: int
    spacing*, margin*: float
    tilecount*, columns*: int
    tileOffset*: Vec2
    objectAlignment*: ObjectAlignment
    tileRenderSize*: TileRenderSize
    fillMode*: FillMode
    tiles*: seq[TilesetTile]
    image*: Option[Image]
    grid*: Option[Grid]
    properties*: Properties
    wangsets*: Option[Wangsets]
    transformations*: Option[Transformations]

  Tile* = TileGid

  Chunk* = object
    x*, y*: float
    width*, height*: int
    tiles*: seq[Tile]

  HAlignment* = enum
    Left, Center, Right, Justify

  VAlignment* = enum
    Top, Center, Bottom

  ObjectKind* = enum
    Obj
    Ellipse
    Point
    Polygon
    Polyline
    Text

  Object* = object
    id: int
    name, class: string
    x*, y*, width*, height*: float
    rotation*: float
    gid*: TileGid
    visible*: bool
    templateFile*: Option[string] # Links to a separate template file
    properties*: Properties

    case kind*: ObjectKind
      of Obj: discard
      of Ellipse: discard
      of Point: discard
      of Polygon, Polyline:
        points*: seq[Vec2]
      of Text:
        text*: string
        fontfamily*: string
        pixelsize*: int
        wrap*, bold*, italic*, underline*, strikeout*, kerning*: bool
        color*: string
        halign*: HAlignment
        valign*: VAlignment

  DrawOrder* = enum
    Topdown
    Index

  LayerKind* = enum
    Tiles
    Objects
    ImageLayer
    Group

  Layer* = object
    id: LayerGid
    name, class: string

    x*, y*: float
    width*, height*: int
    opacity*: float
    visible*: bool
    tintcolor*: string
    offsetx*, offsety*: float
    parallaxx*, parallaxy*: float
    properties*: Properties

    case kind*: LayerKind
      of Tiles:
        data*: Data
      of Objects:
        objects*: seq[Object]
        color*: string
        drawOrder*: DrawOrder = Topdown
      of ImageLayer:
        repeatx, repeaty: bool
        image*: Option[Image]
      of Group:
        layers*: seq[Layer]

  Axis* = enum
    AxisX
    AxisY

  Map* = object
    name: string # This is not part of the tiled spec but I find it useful to have so I can have a unique key for my map
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
    nextLayerId*: LayerGid
    nextObjectid*: ObjectGid
    infinite*: bool

    properties*: Properties

    tilesets*: seq[Tileset]
    layers*: seq[Layer]

    firstGidToTilesetName: Table[TileGid, string]

proc id*(it: Layer|Object|TilesetTile): auto = it.id
proc name*(it: Layer|Object|Tileset|Wangset|Wangcolor|Map): auto = it.name
proc class*(it: Layer|Object|Map|Tileset|TilesetTile|Wangset|Wangcolor): auto = it.class

proc `name=`*(it: var Map, to: string) =
  it.name = to

proc version*(it: Tileset|Map): auto = it.version
proc tiledversion*(it: Tileset|Map): auto = it.tiledversion

proc firstGid*(it: Tileset): auto = it.firstGid
proc source*(it: Tileset): auto = it.source
proc toPercent(v: float): Percent = Percent((v * 100.0).int)

func tileAt*(layer: Layer, x, y: int): Tile =
  if layer.kind == Tiles:
    result = layer.data.tiles[x + y * layer.width]

func tileAt*(layer: Layer, index: int): Tile =
  if layer.kind == Tiles:
    result = layer.data.tiles[index]

const
  ValueMask = 0x1fffffff'u32
  FlipDiagonal = 0x20000000'u32
  FlipVertical = 0x40000000'u32
  FlipHorizontal = 0x80000000'u32

func tileValue*(gid: TileGid): int {.inline.} = (gid.uint32 and ValueMask).int
func hflip*(gid: TileGid): bool {.inline.} = (gid.uint32 and FlipHorizontal) != 0
func vflip*(gid: TileGid): bool {.inline.} = (gid.uint32 and FlipVertical) != 0
func dflip*(gid: TileGid): bool {.inline.} = (gid.uint32 and FlipDiagonal) != 0

## Utility functions

proc extractPoints*(text: string): seq[tuple[x, y: float]] =
  ## extract points ala: 0,0 32,29 0,29
  result = collect:
    for pair in text.split {' '}:
      let coords = pair.split {','}
      (coords[0].parseFloat, coords[1].parseFloat)

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

proc tilesetForTileId*(map: Map, tileId: Tile): TileGid =
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

proc buildProp(prop: XmlNode): Prop =
  result =
    case prop.attr("type")
      of "bool": Prop(kind: BoolProp, boolean: prop.attr("value") == "true")
      of "color": Prop(kind: ColorProp, color: prop.attr("value"))
      of "file": Prop(kind: FileProp, path: prop.attr("value"))
      of "float": Prop(kind: FloatProp, number: prop.attr("value").parseFloat)
      of "object": Prop(kind: ObjectProp, objectValue: prop.attr("value"))
      of "": Prop(kind: StringProp, str: prop.attr("value"))
      else: Prop()

proc buildTileLayer*(x, y: float, width, height: int, infinite = false): Layer =
  let data = 
    if infinite: 
      Data(encoding: NoEncoding, compression: NoCompression, tiles: @[], chunks: @[])
    else: 
      Data(encoding: NoEncoding, compression: NoCompression, tiles: newSeq[Tile](width *
          height), chunks: @[])
  result = Layer(
    kind: Tiles,
    width: width,
    height: height,
    x: x,
    y: y,
    data: data,
    properties: {"background": Prop(kind: BoolProp, boolean: true)}.toTable)

proc buildProperties*(props: XmlNode): Properties =
  collect(for p in props: (p.attr("name"), buildProp(p))).toTable

proc buildProperties*(props: openArray[(string, Prop)]): Properties =
  collect(for p in props: (p[0], p[1])).toTable

proc buildImage(node: XmlNode): Image =
  result.format = node.attr("format")
  result.trans = node.attr("trans")
  result.source = node.attr("source")
  result.width = node.value("width", 0.0)
  result.height = node.value("height", 0.0)

proc buildAnimation(node: XmlNode): Animation =
  for child in node:
    if child.tag != "frame":
      echo "Unsupported child tag in animation: " & child.tag
    else:
      result.add Frame(
        tileid: Tile(child.value("tileid", 0)),
        duration: Milliseconds(child.value("duration", 0)))

proc buildWangcolor(node: XmlNode): Wangcolor =
  result.name = node.attr("name")
  result.class = node.attr("class")
  result.color = node.attr("color")
  result.tile = node.value("tile", 0)
  result.probability = node.value("probability", 0.0).toPercent()
  for child in node:
    if child.tag != "properties":
      echo "Unexpected child tag in wangcolor: " & child.tag
    else:
      result.properties = buildProperties(child)

proc buildWangtile(node: XmlNode): Wangtile =
  result.tileid = Tile(node.value("tileid", 0))
  result.wangid = node.attr("wangid").split({','}).map it => Tile(it.parseInt)
  # NOTE: just realized that these are removed as of Tiled 1.5,
  # we'll keep them in for backward compatibility... for now
  result.hflip = node.value("hflip", false)
  result.vflip = node.value("vflip", false)
  result.dflip = node.value("dflip", false)

proc buildWangset(node: XmlNode): Wangset =
  result.name = node.attr("name")
  result.class = node.attr("class")
  result.tile = node.value("tile", 0)

  for child in node:
    case child.tag
      of "properties": result.properties = buildProperties(child)
      of "wangcolor": result.wangcolors.add buildWangcolor(child)
      of "wangtile": result.wangtiles.add buildWangtile(child)
      else:
        echo "Unexpected child tag in wangset: " & child.tag

proc buildWangsets(node: XmlNode): Wangsets =
  for child in node:
    if child.tag != "wangset":
      echo "Unexpected child tag in wangsets: " & child.tag
    else:
      result.add buildWangset(child)

proc buildObjectGroup(node: XmlNode): Layer

proc buildTilesetTile(node: XmlNode): TilesetTile =
  result.id = node.attr("id")
  result.class = node.attr("class")
  result.probability = node.value("x", 0.0).toPercent()
  result.x = node.value("x", 0.0)
  result.y = node.value("y", 0.0)
  result.width = node.value("width", 0.0)
  result.height = node.value("height", 0.0)

  for child in node:
    case child.tag:
      of "properties": result.properties = buildProperties(child)
      of "animation": result.animation = some buildAnimation(child)
      of "objectgroup": result.objectGroup = some buildObjectGroup(child)
      of "image": result.image = some buildImage(child)
      else:
        echo "Unexpected child tag in tile: " & child.tag
        discard

proc loadTilesetFields(tileset: var Tileset, node: XmlNode) =
  if tileset.firstGid == 0:
    tileset.firstGid =
      if node.attr("firstgid") == "": 1
      else: node.attr("firstgid").parseInt

  tileset.source = node.attr("source")
  tileset.name = node.attr("name")
  tileset.class = node.attr("class")
  tileset.tilewidth = node.value("tilewidth", 0)
  tileset.tileheight = node.value("tileheight", 0)
  tileset.spacing = node.value("spacing", 0.0)
  tileset.margin = node.value("margin", 0.0)
  tileset.tilecount = node.value("tilecount", 0)
  tileset.columns = node.value("columns", 0)
  tileset.objectAlignment =
    case node.attr("objectalignment"):
      of "unspecified": Unspecified
      of "topleft": TopLeft
      of "top": Top
      of "topright": TopRight
      of "center": Center
      of "right": Right
      of "bottomleft": BottomLeft
      of "bottom": Bottom
      of "bottomright": BottomRight
      else: Unspecified

  tileset.tileRenderSize =
    case node.attr("tilerendersize")
      of "tile": TileSize
      of "grid": GridSize
      else: TileSize

  tileset.fillMode =
    case node.attr("fillmode")
      of "stretch": Stretch
      of "preserve-aspect-fit": PreserveAspectFit
      else: Stretch

  for child in node:
    case child.tag
      of "image": tileset.image = some buildImage(child)
      of "tile": tileset.tiles.add buildTilesetTile(child)
      of "properties": tileset.properties = buildProperties(child)
      of "wangsets": tileset.wangsets = some buildWangsets(child)
      of "grid":
        var grid = Grid()
        grid.orientation =
          case child.attr("orientation")
            of "orthogonal": Orthogonal
            of "isometric": Isometric
            else: Orthogonal
        grid.width = child.value("width", 0.0)
        grid.height = child.value("height", 0.0)
        tileset.grid = some grid
      of "tileoffset":
        tileset.tileOffset.x = child.value("x", 0.0)
        tileset.tileOffset.y = child.value("y", 0.0)
      of "transformations":
        var transform = Transformations()
        transform.hflip = child.value("hflip", false)
        transform.vflip = child.value("vflip", false)
        transform.preferuntransformed = child.value("preferuntransformed", false)
        tileset.transformations = some transform
      else:
        echo "Unhandled tileset child tag: " & child.tag

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

proc buildTiles(buff: string, encoding: Encoding,
    compression: Compression): seq[Tile] =

  proc handleUncompress(data: string): string =
    result =
      case compression
        of NoCompression: data
        of Gzip: uncompress(data, dfGzip)
        of Zlib: uncompress(data, dfZlib)
        of Zstd:
          # TODO: Look into supporting zstd compression by using this library:
          # https://github.com/wltsmrz/nim_zstd
          # optionally we could provide a hook so that you could pass in any uncompress function.
          echo "Error unsupported compression (ZSTD)"
          data

  if encoding == Base64:
    const sz = sizeof(uint32)

    let
      decoded = buff.decode().handleUncompress()
      chrs = toSeq(decoded.items)
      length = (decoded.len() / sz).int

    for i in 0..<length:
      let
        r = chrs[i*sz+0].uint8
        g = chrs[i*sz+1].uint8
        b = chrs[i*sz+2].uint8
        a = chrs[i*sz+3].uint8
        id: uint32 = (a shl 24) or (b shl 16) or (g shl 8) or r

      result.add(Tile(id))
  else:
    return buff.split({',', '\n'}).filterIt(it != "").map it => Tile(parseInt(it))

proc buildChunk(node: XmlNode, encoding: Encoding,
    compression: Compression): Chunk =
  result.x = node.value("x", 0.0)
  result.y = node.value("y", 0.0)
  result.width = node.value("width", 0)
  result.height = node.value("height", 0)
  result.tiles = node.innerText.buildTiles(encoding, compression)

proc buildData(data: XmlNode): Data =
  case data.attr("encoding")
    of "base64": result.encoding = Base64
    of "csv": result.encoding = Csv
    else:
      let en = data.attr("encoding")
      echo &"Unexpected encoding '{en}' for data."

  case data.attr("compression"):
    of "gzip": result.compression = Gzip
    of "zlib": result.compression = Zlib
    of "zstd": result.compression = Zstd
    else: discard

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
      result.tiles = node.innerText.buildTiles(result.encoding,
          result.compression)

proc loadTextFields(text: var Object, node: XmlNode) =
  text = Object(kind: Text)
  text.pixelsize = node.value("pixelsize", 0)
  text.wrap = node.value("wrap", false)
  text.color = node.attr("color")
  text.bold = node.value("bold", false)
  text.italic = node.value("italic", false)
  text.underline = node.value("underline", false)
  text.strikeout = node.value("strikeout", false)
  text.kerning = node.value("kerning", true)
  text.halign =
    case node.attr("halign")
      of "left": Left
      of "center": Center
      of "right": Right
      of "justify": Justify
      else: Left
  text.valign =
    case node.attr("valign")
      of "top": Top
      of "center": Center
      of "bottom": Bottom
      else: Top
  text.text = node.innerText

proc buildObject(node: XmlNode): Object =
  for child in node:
    case child.tag
      of "properties": result.properties = buildProperties(child)
      of "ellipse":
        result = Object(kind: Ellipse)
      of "point":
        result = Object(kind: Point)
      of "polygon":
        result = Object(kind: Polygon)
        result.points = child.attr("points").extractPoints()
      of "polyline":
        result = Object(kind: Polyline)
        result.points = child.attr("points").extractPoints()
      of "text":
        result.loadTextFields(child)
      else:
        echo "Unexpected tag for object child: " & child.tag

  result.id = node.value("id", 0)
  result.name = node.attr("name")
  result.class = node.attr("class")
  result.x = node.value("x", 0.0)
  result.y = node.value("y", 0.0)
  result.width = node.value("width", 0.0)
  result.height = node.value("height", 0.0)
  result.rotation = node.value("rotation", 0.0)
  result.gid = node.value("gid", 0)
  result.visible = if node.attr("visible") == "": true else: node.value(
      "visible", true)

proc loadBasicLayerFields(layer: var Layer, node: XmlNode) =
  layer.id = node.attr("id")
  layer.name = node.attr("name")
  layer.class = node.attr("class")
  layer.x = node.value("x", 0.0)
  layer.y = node.value("y", 0.0)
  layer.width = node.value("width", 0)
  layer.height = node.value("height", 0)
  layer.visible = if node.attr("visible") == "": true else: node.value(
      "visible", true)
  layer.tintcolor = node.attr("tintcolor")
  layer.offsetx = node.value("offsetx", 0.0)
  layer.offsety = node.value("offsety", 0.0)
  layer.parallaxx = node.value("parallaxx", 0.0)
  layer.parallaxy = node.value("parallaxy", 0.0)

proc buildObjectGroup(node: XmlNode): Layer =
  result = Layer(kind: Objects)
  loadBasicLayerFields(result, node)

  result.color = node.attr("color")
  result.drawOrder =
    case node.attr("draworder")
      of "index": Index
      of "topdown": Topdown
      else: Topdown

  for child in node:
    case child.tag
      of "properties":
        result.properties = buildProperties(child)
      of "object":
        result.objects.add buildObject(child)
      else:
        echo "Unexpected tag in objectgroup: " & child.tag
        discard

proc buildLayer(node: XmlNode): Layer =
  result.kind = Tiles
  loadBasicLayerFields(result, node)

  for subNode in node:
    case subNode.tag
      of "data":
        result.data = buildData(subNode)
      of "properties":
        result.properties = buildProperties(subNode)
      else:
        echo &"Unexpected child tag for layer: {subNode.tag}"

proc buildTilemap(node: XmlNode, path: string): Map =
  result = Map()
  result.name = extractFilename(path).replace(".tmx", "")
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
      of "orthogonal": Orthogonal
      of "orthographic": Orthographic
      of "isometric": Isometric
      of "staggered": Staggered
      of "hexagonal": Hexagonal
      else: Orthogonal

  result.renderOrder =
    case node.attr("renderorder"):
      of "right-down": RightDown
      of "right-up": LeftDown
      of "left-up": RightUp
      of "left-down": LeftUp
      else: RightDown

  result.nextLayerId = node.attr("nextlayerid")
  result.nextObjectid = node.attr("nextobjectid")

  result.hexSideLength = node.value("hexsidelength", 0)
  result.staggerIndex = node.value("staggerindex", 0)

  result.parallaxOriginX = node.value("parallaxoriginx", 0)
  result.parallaxOriginY = node.value("parallaxoriginy", 0)
  result.backgroundColor = node.value("backgroundcolor", "")

  for item in node:
    case item.tag:
      of "tileset": result.tilesets.add buildTileset(item, path)
      of "layer": result.layers.add buildLayer(item)
      of "objectgroup": result.layers.add buildObjectGroup(item)
      of "properties": result.properties = buildProperties(item)
      else: echo "Unhandled tag: ", item.tag

  result.firstGidToTilesetName = initTable[TileGid, string]()

  for tileset in result.tilesets:
    result.firstGidToTilesetName[tileset.firstGid] = tileset.name

proc getTilesetNameGivenFirstGid*(map: Map, uid: TileGid): string =
  map.firstGidToTilesetName[uid]

type
  LoadResultKind = enum
    tiledOk
    tiledError

  LoadErrorKind = enum
    fileNotFound

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
    return errorResult(fileNotFound, "File does not exist.")

  result = LoadResult(
    kind: tiledOk,
    tiledMap: buildTilemap(
      readFile(path).newStringStream().parseXml(),
      path
    )
  )
