import
  xmlparser,
  xmltree,
  streams,
  strutils,
  parseutils,
  strformat,
  os,
  tables,
  ospaths,
  typeinfo,
  base64,
  math,
  terminal,
  zippy

type
  TiledGid* = distinct uint32
    ## A "Global Tile ID".
    ## 
    ## This is a value referring to a tile from any of the tilesets used by the map.
    ## The upper bits are used as flags for horizontal, vertical and diagonal flipping.

  TiledColor* = (float, float, float, float)
    ## Color RGBA values range from 0.0 - 1.0

  TiledRegion* = object
    ## Sprite region for each tile
    x, y, width, height: int

  TiledOrientation* {.pure.} = enum
    ## Tile map orientation
    Orthogonal
    Orthographic

  TiledRenderorder* {.pure.} = enum
    RightDown

  TiledValueType* = enum
    ## All of the different types that an objects property could be
    tvInt
    tvFloat
    tvString
    tvColor
    tvBool
    tvObject

  TiledValue* = ref object
    ## Value of a property
    case valueType*: TiledValueType
    of tvInt:
      valueInt*: int
    of tvFloat:
      valueFloat*: float
    of tvString:
      valueString*: string
    of tvColor:
      valueColor*: (float, float, float, float)
    of tvBool:
      valueBool*: bool
    of tvObject:
      valueObjectId*: int

  TiledProperties* = TableRef[string, TiledValue]

  TiledObject* = ref object of RootObj
    ## An object created by tiled using the shape tools
    x*, y*, width*, height*, rotation*: float
    id*: int
    gid*: TiledGid
    name*: string
    objectType*: string
    properties*: TiledProperties

  TiledPolygon* = ref object of TiledObject
    points*: seq[(float, float)]

  TiledPolyline* = ref object of TiledObject
    points*: seq[(float, float)]

  TiledPoint* = ref object of TiledObject
  TiledEllipse* = ref object of TiledObject

  TiledFrame* = object
    tileid: int
    duration: int

  TiledTileCollisionShape* = ref object of RootObj
    id*: int
    x*, y*: float
  TiledTileCollisionShapesPoint* = ref object of TiledTileCollisionShape
  TiledTileCollisionShapesRect* = ref object of TiledTileCollisionShape
    width*, height*: float
  TiledTileCollisionShapesPolygon* = ref object of TiledTileCollisionShape
    points*: seq[(float, float)]

  TiledTile* = object
    tileid: int
    tileType: string
    animation: seq[TiledFrame]
    collisionShapes*: seq[TiledTileCollisionShape]
    properties*: TiledProperties

  TiledTileset* = ref object
    ## Contains the data for each tile in the sprite sheet
    ## and the size of each tile and image
    name: string
    imagePath: string
    tilewidth, tileheight: int
    firstgid: int
    width, height: int
    tilecount: int
    columns: int
    regions: seq[TiledRegion]
    properties: TiledProperties
    tiles: TableRef[int, TiledTile]

  TiledLayer* = ref object
    ## Layer in the tile map
    name: string
    width, height: int
    properties: TiledProperties
    tiles: seq[TiledGid]

  TiledObjectGroup* = ref object
    ## Layer for the objects on the map
    objects: seq[TiledObject]
    name: string

  TiledMap* = ref object
    version: string
    tiledversion: string
    orientation: TiledOrientation
    renderorder: TiledRenderorder

    nextlayerid, nextobjectid: int

    width, height: int
    tilewidth, tileheight: int
    infinite: bool

    properties: TiledProperties

    tilesets: seq[TiledTileset]
    layers: seq[TiledLayer]
    objectGroups: seq[TiledObjectGroup]

const
  ValueMask = 0x1fffffff'u32
  FlipDiagonal = 0x20000000'u32
  FlipVertical = 0x40000000'u32
  FlipHorizontal = 0x80000000'u32

func value*(gid: TiledGid): int {.inline.} = (gid.uint32 and ValueMask).int
func hflip*(gid: TiledGid): bool {.inline.} = (gid.uint32 and FlipHorizontal) != 0
func vflip*(gid: TiledGid): bool {.inline.} = (gid.uint32 and FlipVertical) != 0
func dflip*(gid: TiledGid): bool {.inline.} = (gid.uint32 and FlipDiagonal) != 0

proc extractPoints*(pstr: string): seq[tuple[x, y: float]] =
  ## extract points ala: 0,0 32,29 0,29
  var pos = 0
  while pos < pstr.len:
    var xstr, ystr: int
    pos += pstr.parseInt(xstr, pos)
    pos.inc # skip ,
    pos += pstr.parseInt(ystr, pos)
    pos.inc # skip ' '
    result.add (xstr.float, ystr.float)

proc `$`*(v: TiledValue): string =
  result = "TiledValue {valueType: " & $v.valueType & ", "
  result &= (
    case v.valueType
    of tvInt: "valueInt: " & $v.valueInt
    of tvFloat: "valueFloat: " & $v.valueFloat
    of tvString: "valueString: " & $v.valueString
    of tvColor: "valueColor: " & $v.valueColor
    of tvBool: "valueBool: " & $v.valueBool
    of tvObject: "valueObjectId: " & $v.valueObjectId
  )
  result &= "}"
  
proc `$`*(r: TiledRegion): string =
  result = "TiledRegion {\n"
  result &= "   x: " & $r.x & "\n"
  result &= "   y: " & $r.y & "\n"
  result &= "   w: " & $r.width & "\n"
  result &= "   h: " & $r.height & "\n}\n"

{.push inline.}

# Public properties for the TiledMap
proc version*(map: TiledMap): string = map.version
proc tiledversion*(map: TiledMap): string = map.tiledversion
proc orientation*(map: TiledMap): TiledOrientation = map.orientation
proc renderorder*(map: TiledMap): TiledRenderorder = map.renderorder
proc width*(map: TiledMap): int = map.width
proc height*(map: TiledMap): int = map.height
proc tilewidth*(map: TiledMap): int = map.tilewidth
proc tileheight*(map: TiledMap): int = map.tileheight
proc infinite*(map: TiledMap): bool = map.infinite
proc tilesets*(map: TiledMap): seq[TiledTileset] = map.tilesets
proc layers*(map: TiledMap): seq[TiledLayer] = map.layers
proc objectGroups*(map: TiledMap): seq[TiledObjectGroup] = map.objectGroups

# Public properties for the TiledLayer
proc name*(layer: TiledLayer): string = layer.name
proc width*(layer: TiledLayer): int = layer.width
proc height*(layer: TiledLayer): int = layer.height
proc tiles*(layer: TiledLayer): seq[TiledGid] = layer.tiles
proc properties*(layer: TiledLayer): auto = layer.properties

# Public properties for the TiledObjectGroup
proc objects*(layer: TiledObjectGroup): seq[TiledObject] = layer.objects
proc name*(layer: TiledObjectGroup): string = layer.name

# Public properties for the TiledTileset
proc name*(tileset: TiledTileset): string = tileset.name
proc imagePath*(tileset: TiledTileset): string = tileset.imagePath
proc tilewidth*(tileset: TiledTileset): int = tileset.tilewidth
proc tileheight*(tileset: TiledTileset): int = tileset.tileheight
proc firstgid*(tileset: TiledTileset): int = tileset.firstgid
proc width*(tileset: TiledTileset): int = tileset.width
proc height*(tileset: TiledTileset): int = tileset.height
proc tilecount*(tileset: TiledTileset): int = tileset.tilecount
proc columns*(tileset: TiledTileset): int = tileset.columns
proc regions*(tileset: TiledTileset): seq[TiledRegion] = tileset.regions
proc properties*(tileset: TiledTileset): auto = tileset.properties
proc tiles*(tileset: TiledTileset): auto = tileset.tiles

# Public properties for the TiledRegion
proc x*(r: TiledRegion): auto = r.x
proc y*(r: TiledRegion): auto = r.y
proc width*(r: TiledRegion): auto = r.width
proc height*(r: TiledRegion): auto = r.height

# Public properties for the TiledObject
proc x*(r: TiledObject): auto = r.x
proc id*(r: TiledObject): auto = r.id
proc gid*(r: TiledObject): auto = r.gid
proc y*(r: TiledObject): auto = r.y
proc width*(r: TiledObject): auto = r.width
proc height*(r: TiledObject): auto = r.height
proc name*(r: TiledObject): auto = r.name
proc objectType*(r: TiledObject): auto = r.objectType
proc properties*(r: TiledObject): auto = r.properties

# Tiled Frame properties
proc tileid*(frame: TiledFrame): auto = frame.tileid
proc duration*(frame: TiledFrame): auto = frame.duration

# Tiled Tile properties
proc tileid*(tile: TiledTile): auto = tile.tileid
proc animation*(tile: TiledTile): auto = tile.animation
proc properties*(tile: TiledTile): auto = tile.properties

{.pop.}

proc `$`*(o: TiledPolygon): auto =
  result = "TiledPolygon{\n"
  result &= "   x:" & $o.x & "\n"
  result &= "   y:" & $o.y & "\n"
  result &= "   width:" & $o.width & "\n"
  result &= "   height:" & $o.height & "\n"
  result &= "   points: ["
  for p in o.points:
    result &= fmt"({p[0]},{p[1]}),"
  result &= "]\n}"

proc `$`*(o: TiledPolyline): auto =
  result = "TiledPolyline{\n"
  result &= "   x:" & $o.x & "\n"
  result &= "   y:" & $o.y & "\n"
  result &= "   width:" & $o.width & "\n"
  result &= "   height:" & $o.height & "\n"
  result &= "   points: ["
  for p in o.points:
    result &= fmt"({p[0]},{p[1]}),"
  result &= "]\n}"

proc `$`*(o: TiledPoint): auto =
  result = "TiledPoint{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`*(o: TiledEllipse): auto =
  result = "TiledEllipse{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`*(o: TiledObject): auto =
  if o of TiledPoint: return $(o.TiledPoint)
  if o of TiledEllipse: return $(o.TiledEllipse)
  if o of TiledPolygon: return $(o.TiledPolygon)
  if o of TiledPolyline: return $(o.TiledPolyline)
  result = "TiledObject{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`*(f: TiledFrame): auto =
  result = "TiledFrame{tileid: " & $f.tileid & ", duration: " & $f.duration & "}"

proc `$`*(t: TiledTile): auto =
  result = "TiledTile{" & "\n"
  result &= "   tileid:" & $t.tileid & "\n"
  result &= "   animation: @[" & "\n"
  for frame in t.animation:
    result &= "      " & $frame & ",\n"
  result &= "   ]\n}"

proc `$`*(t: TiledTileset): auto =
  result  = "TiledTileset{\n"
  result &= "   name:" & t.name & "\n"
  result &= "   path:" & t.imagePath & "\n"
  result &= "   firstgid:" & $t.firstgid & "\n"
  result &= "   tilewidth:" & $t.tilewidth & "\n"
  result &= "   tileheight:" & $t.tileheight & "\n"
  result &= "   columns:" & $t.columns & "\n"
  result &= "   width:" & $t.width & "\n"
  result &= "   height:" & $t.height & "\n"
  result &= "}"

proc assertWarn(expression: bool, msg: string, color = true): bool =
  result = expression
  if not expression:
    if color:
     styledWriteLine(stdout, fgYellow, "[nim_tiled]::Warning:: ", resetStyle, msg)
    else:
      echo fmt"[nim_tiled]::Warning:: {msg}"

proc addProperties(properties: TiledProperties; xml: XmlNode) =
  ## Get all key/value pairs from a <properties> XML node and add them to the given properties table.

  proc hexStringToColor(color_str: string): auto =
    let without_hash = color_str[1..len(color_str)-1]
    let a = without_hash[0..1].parseHexInt().float / 255.0
    let r = without_hash[2..3].parseHexInt().float / 255.0
    let g = without_hash[4..5].parseHexInt().float / 255.0
    let b = without_hash[6..7].parseHexInt().float / 255.0
    result = (r, g, b, a)
  
  for propXml in xml:
    let theTypeStr = propXml.attr("type")
    let name = propXml.attr("name")
    let str = propXml.attr("value")
    properties[name] = case theTypeStr:
      of "color": TiledValue(valueType: tvColor, valueColor: hexStringToColor(str))
      of "float": TiledValue(valueType: tvFloat, valueFloat: str.parseFloat)
      of "int": TiledValue(valueType: tvInt, valueInt: str.parseInt)
      of "bool": TiledValue(valueType: tvBool, valueBool: str == "true")
      of "object": TiledValue(valueType: tvObject, valueObjectId: str.parseInt)
      else: TiledValue(valueType: tvString, valueString: str)

proc newTiledProperties*(xml: XmlNode = nil): TiledProperties =
  result = newTable[string, TiledValue]()
  if xml != nil:
    result.addProperties(xml)

proc newTiledRegion*(x, y, width, height: int): TiledRegion =
  TiledRegion(x: x, y: y, width: width, height: height)

proc loadTileset*(theXml: XmlNode): TiledTileset =
  ## Load a Tiled tileset from an XML node.
  result = TiledTileset(
    tiles: newTable[int, TiledTile]()
  )

  result.name         = theXml.attr "name"
  result.tilewidth    = theXml.attr("tilewidth").parseInt
  result.tileheight   = theXml.attr("tileheight").parseInt
  result.tilecount    = theXml.attr("tilecount").parseInt
  result.columns      = theXml.attr("columns").parseInt
  result.properties   = newTiledProperties(theXml.child("properties"))

  let theImage = theXml[0]

  # Load tiles in the tileset
  var first = true
  for tile in theXml:
    if first: first = false; continue
    if tile.attr("id") == "":
      echo "tile has not id: ", tile
      continue
    let tileid = tile.attr("id").parseInt

    var tiledTile = TiledTile(
      tileid: tileid,
      tileType: tile.attr("type"),
      properties: newTiledProperties(tile.child("properties")),
      animation: @[]
    )

    let animations = tile.findAll("animation")
    if animations.len > 0:
      for frame in animations[0]:
        var frame = TiledFrame(
          tileid: frame.attr("tileid").parseInt,
          duration: frame.attr("duration").parseInt)
        tiledTile.animation.add(frame)

    # Collision shapes are:
    # objectgroup -> object(s)
    let objectgroups = tile.findAll("objectgroup")
    # there shoould be only one
    if objectgroups.len >= 1:
      let objectgroup = objectgroups[0]
      let collisionShapes = objectgroup.findAll("object")
      for collisionShape in collisionShapes:
        let id = collisionShape.attr("id")
        let x = collisionShape.attr("x")
        let y = collisionShape.attr("y")
        let width = collisionShape.attr("width")
        let height = collisionShape.attr("height")
        # todo only point and rect are currently supported
        if not collisionShape.child("polygon").isNil:
          # Polygon
          let polygon = collisionShape.child("polygon")
          var tiledTileCollisionShapesPolygon = TiledTileCollisionShapesPolygon()
          tiledTileCollisionShapesPolygon.id = id.parseInt()
          tiledTileCollisionShapesPolygon.x = x.parseFloat()
          tiledTileCollisionShapesPolygon.y = y.parseFloat()
          tiledTileCollisionShapesPolygon.points =
            collisionShape.child("polygon").attr("points").extractPoints()
          tiledTile.collisionShapes.add tiledTileCollisionShapesPolygon
        elif width == "" and height == "":
          # shape is a point
          var tiledTileCollisionShapesPoint = TiledTileCollisionShapesPoint()
          tiledTileCollisionShapesPoint.id = id.parseInt()
          tiledTileCollisionShapesPoint.x = x.parseFloat()
          tiledTileCollisionShapesPoint.y = y.parseFloat()
          # if not tiledTile.collisionShapes.hasKey(tileId):
          #   tiledTile.collisionShapes[tileId] = @[]
          # tiledTile.collisionShapes[tileId].add tiledTileCollisionShapesPoint
          tiledTile.collisionShapes.add tiledTileCollisionShapesPoint
        else:
          # shape is a rect
          var tiledTileCollisionShapesRect = TiledTileCollisionShapesRect()
          tiledTileCollisionShapesRect.id = id.parseInt()
          tiledTileCollisionShapesRect.x = x.parseFloat()
          tiledTileCollisionShapesRect.y = y.parseFloat()
          tiledTileCollisionShapesRect.width = width.parseFloat()
          tiledTileCollisionShapesRect.height = height.parseFloat()
          # if not tiledTile.collisionShapes.hasKey(tileId):
          #   tiledTile.collisionShapes[tileId] = @[]
          # tiledTile.collisionShapes[tileId].add tiledTileCollisionShapesRect
          tiledTile.collisionShapes.add tiledTileCollisionShapesRect


    result.tiles.add(tileid, tiledTile)

  let width = theImage.attr("width").parseInt
  let height = theImage.attr("height").parseInt

  result.imagePath = theImage.attr("source")
  result.width = width
  result.height = height

  if theXml.attr("firstgid") != "":
    result.firstgid = theXml.attr("firstgid").parseInt

  #TODO: Check the assets manager
  #let region_string = $result.tilewidth & "x" & $result.tileheight
  # result.regions = newSeq[]

  # let imageXml = theXml[0]
  # let tpath = parentDir(path) & "/" & imageXml.attr("source")

  let num_tiles_w = (width / result.tilewidth).int
  let num_tiles_h = (height / result.tileheight).int

  result.regions = newSeq[TiledRegion](num_tiles_w * num_tiles_h)
  var index = 0
  for y in 0..<num_tiles_h:
    for x in 0..<num_tiles_w:
      result.regions[index] = newTiledRegion(
        x * result.tilewidth,
        y * result.tileheight,
        result.tilewidth,
        result.tileheight
      )
      index += 1

proc loadTileset*(path: string): TiledTileset =
  ## Load a tileset from disk.
  ## 
  ## .. note::
  ##    The `firstgid` will not be set for tilesets loaded in this way, which makes it
  ##    hard to know which tile is being referred to when you are reading the map.
  ## 
  ##    Still you can use this procedure if you only want to work with a tileset directly.
  ## 
  result = TiledTileset()

  if not assertWarn(fileExists path, fmt"cannot find tileset: {path}"):
    return

  let theXml = readFile(path)
    .newStringStream()
    .parseXml()

  result = loadTileset theXml


proc findTilesetByGid*(map: TiledMap; gid: TiledGid): TiledTileset =
  ## Find the tileset which a certain Global Tile ID belongs to.
  let val = gid.value
  for tileset in map.tilesets:
    if val < tileset.firstgid:
      break
    result = tileset


proc loadTiledMap*(path: string): TiledMap =

  ## Loads a Tiled tmx file into a nim object
  if not assertWarn(fileExists path, fmt"cannot find tiled map: {path}"):
    return

  result = TiledMap(
    tilesets: newSeq[TiledTileset](),
    layers: newSeq[TiledLayer](),
    objectGroups: newSeq[TiledObjectGroup]()
  )

  let theXml = readFile(path)
    .newStringStream()
    .parseXml()

  result.version = theXml.attr "version"
  result.tiledversion = theXml.attr "tiledversion"

  result.orientation =
    if theXml.attr("orientation") == "orthogonal":
      TiledOrientation.Orthogonal
    else:
      TiledOrientation.Orthogonal

  result.renderorder =
    if theXml.attr("renderorder") == "right-down":
      TiledRenderorder.RightDown
    else:
      echo "Nim Tiled currently only supports: " & $TiledRenderorder.RightDown & " render order"
      TiledRenderorder.RightDown

  if theXml.attr("nextlayerid") != "":
    result.nextlayerid = theXml.attr("nextlayerid").parseInt

  if theXml.attr("nextobjectid") != "":
    result.nextobjectid = theXml.attr("nextobjectid").parseInt

  result.width = theXml.attr("width").parseInt
  result.height = theXml.attr("height").parseInt

  result.tilewidth = theXml.attr("tilewidth").parseInt
  result.tileheight = theXml.attr("tileheight").parseInt

  result.infinite = (theXml.attr("infinite") != "0")

  if not assertWarn(result.infinite == false, fmt"Nim Tiled currently doesn't support infinite maps"):
    return

  result.properties = newTiledProperties(theXml.child("properties"))

  let tileset_xmlnodes = theXml.findAll "tileset"
  for node in tileset_xmlnodes:
    let sourcePath = node.attr("source")
    let tileset = 
      if sourcePath == "": loadTileset(node)
      else: loadTileset(parentDir(path) & "/" & sourcePath)
    tileset.firstgid = node.attr("firstgid").parseInt
    result.tilesets.add tileset

  let layers_xmlnodes = theXml.findAll "layer"
  let objects_xmlnodes = theXml.findAll "objectgroup"

  for layerXml in layers_xmlnodes:
    let layer = TiledLayer(
      name: layerXml.attr "name",
      width: layerXml.attr("width").parseInt,
      height: layerXml.attr("height").parseInt,
      properties: newTiledProperties()
    )

    layer.tiles = newSeq[TiledGid](layer.width * layer.height)

    var dataIndex = 0
    if layerXml.child("properties") != nil:
      inc dataIndex
      layer.properties.addProperties(layerXml.child("properties"))

    let dataXml = layerXml[dataIndex]
    let dataInnerXml = dataXml[0]

    var encoding = "xml"
    if dataXml.attr("encoding") != "":
      encoding = dataXml.attr("encoding")

    case encoding
    of "csv":
      let dataText = dataInnerXml.rawText
      let dataTextLen = dataText.len
      var cursor = 0
      var index = 0
      var token = ""

      while cursor < dataTextLen:
        cursor += parseUntil(dataText, token, ',', cursor) + 1
        token.removeSuffix()
        token.removePrefix()
        layer.tiles[index] = token.parseUInt.TiledGid
        index += 1

    of "base64":
      let dataText = dataInnerXml.rawText
      var compression = "none"
      if dataXml.attr("compression") != "":
        compression = dataXml.attr("compression")

      var decoded = dataText.strip()
      decoded = decode(decoded)

      case compression
      of "gzip":
        decoded = uncompress(decoded, dataFormat  = dfGzip)
      of "zlib":
        decoded = uncompress(decoded, dataFormat  = dfZlib)
      else:
        discard

      var seqOfChars = newSeq[char](decoded.len)
      var i = 0
      for c in decoded:
        seqOfChars[i] = c
        inc i

      let length = (decoded.len() / sizeof(uint32)).int

      for i in 0..<length:
        let r = uint8 seqOfChars[(i*sizeof(uint32))+0]
        let g = uint8 seqOfChars[(i*sizeof(uint32))+1]
        let b = uint8 seqOfChars[(i*sizeof(uint32))+2]
        let a = uint8 seqOfChars[(i*sizeof(uint32))+3]
        var num: uint32 = (a shl 24) or (b shl 16) or (g shl 8) or r

        layer.tiles[i] = num.TiledGid

    of "xml":
      var index = 0
      for tile in dataXml:
        var gid = 0.TiledGid
        if tile.attr("gid") != "":
          gid = tile.attr("gid").parseUInt.TiledGid
        layer.tiles[index] = gid
        inc index
    else:
      echo "Nim Tiled does not support the encoding type: " & encoding
      return

    result.layers.add(layer)

  for objectsXml in objects_xmlnodes:

    var objectGroup = TiledObjectGroup(objects: newSeq[TiledObject]())
    objectGroup.name = objectsXml.attr("name")
    result.objectGroups.add objectGroup

    for objXml in objectsXml:
      let x = objXml.attr("x").parseFloat
      let y = objXml.attr("y").parseFloat

      var id = 0
      var hasGid = false
      var gid = 0.TiledGid
      var name = ""
      var otype = ""
      var width = 0.0
      var height = 0.0
      var rotation = 0.0

      id = objXml.attr("id").parseInt

      try:
        gid = objXml.attr("gid").parseUInt.TiledGid
        hasGid = true
      except: discard

      try:
        name = objXml.attr("name")
      except: discard

      try:
        otype = objXml.attr("type")
      except: discard

      try:
        width = objXml.attr("width").parseFloat
      except: discard

      try:
        height = objXml.attr("height").parseFloat
      except: discard

      try:
        rotation = objXml.attr("rotation").parseFloat
      except: discard

      let properties = newTiledProperties()

      # Copy object properties from tile.
      if hasGid:
        let tileset = result.findTilesetByGid(gid)
        if tileset != nil:
          let tile = addr tileset.tiles[gid.value - tileset.firstgid]
          properties[] = tile.properties[]
          # Also copy tile type if we don't have our own.
          if otype == "":
            otype = tile.tileType
      
      # Override with own properties.
      if objXml.child("properties") != nil:
        properties.addProperties(objXml.child("properties"))

      var isRect = true
      for subXml in objXml:
        case subXml.tag
        of "polygon":
          isRect = false

          var o = TiledPolygon(
            id: id, x: x, y: y, width: width, height: height,
            rotation: rotation,
            points: newSeq[(float, float)](),
            name: name,
            objectType: otype,
            properties: properties
          )

          o.points = extractPoints(subXml.attr("points"))
          objectGroup.objects.add o

        of "polyline":
          isRect = false

          var o = TiledPolyline(
            id: id, x: x, y: y, width: width, height: height,
            rotation: rotation,
            points: newSeq[(float, float)](),
            name: name,
            objectType: otype,
            properties: properties
          )

          o.points = extractPoints(subXml.attr("points"))
          objectGroup.objects.add o

        of "point":
          isRect = false

          var o = TiledPoint(
            id: id,
            x: x,
            y: y,
            width: 0,
            height: 0,
            rotation: rotation,
            name: name,
            objectType: otype,
            properties: properties
          )
          objectGroup.objects.add o

        of "ellipse":
          isRect = false

          var o = TiledEllipse(
            id: id,
            x: x,
            y: y,
            width: width,
            height: height,
            rotation: rotation,
            name: name,
            objectType: otype,
            properties: properties
          )
          objectGroup.objects.add o

        of "properties": discard
        else:
          echo fmt"Nim Tiled unsuported object type: {subXml.tag}"

      if isRect:
        var o = TiledObject(
          id: id,
          gid: gid,
          x: x, y: y, width: width, height: height,
          rotation: rotation,
          name: name,
          objectType: otype,
          properties: properties
        )

        objectGroup.objects.add(o)
