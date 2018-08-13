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
    nim_tiled/private/zlib

type
    ## Color RGBA values range from 0.0 - 1.0
    TiledColor* =
      (float, float, float, float)

    TiledRegion* = object
        ## Sprite region for each tile
        x, y, width, height : int

    TiledOrientation* {.pure.} = enum
        ## Tile map orientation
        Orthogonal,
        Orthographic

    TiledRenderorder* {.pure.} = enum
        RightDown

    TiledValueType* = enum
      ## All of the different types that an objects property could be
      tvInt,
      tvFloat,
      tvString,
      tvColor,
      tvBool

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

    TiledObject* = ref object of RootObj
      ## An object created by tiled using the shape tools
      x, y, width, height, rotation: float
      name: string
      objectType: string
      properties: TableRef[string, TiledValue]

    TiledPolygon* = ref object of TiledObject
      points: seq[(float, float)]

    TiledPolyline* = ref object of TiledObject
      points: seq[(float, float)]

    TiledPoint* = ref object of TiledObject
    TiledEllipse* = ref object of TiledObject

    TiledFrame* = object
      tileid: int
      duration: int

    TiledTile* = object 
      tileid: int
      animation: seq[TiledFrame]

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

        tiles: TableRef[int, TiledTile]

    TiledLayer* = ref object
        ## Layer in the tile map
        name: string
        width, height: int
        tiles: seq[int]

    TiledObjectGroup* = ref object
        ## Layer for the objects on the map
        objects: seq[TiledObject]

    TiledMap* = ref object
        version: string
        tiledversion: string
        orientation: TiledOrientation
        renderorder: TiledRenderorder

        nextlayerid, nextobjectid: int

        width, height: int
        tilewidth, tileheight: int
        infinite: bool

        tilesets: seq[TiledTileset]
        layers: seq[TiledLayer]
        objectGroups: seq[TiledObjectGroup]

proc `$`* (r: TiledRegion): string=
    result = "TiledRegion {\n"
    result &= "   x: " & $r.x & "\n"
    result &= "   y: " & $r.y & "\n"
    result &= "   w: " & $r.width & "\n"
    result &= "   h: " & $r.height & "\n}\n"

# Public properties for the TiledMap
proc version*       (map: TiledMap): string {.inline.} = map.version
proc tiledversion*  (map: TiledMap): string {.inline.} = map.tiledversion
proc orientation*   (map: TiledMap): TiledOrientation {.inline.} = map.orientation
proc renderorder*   (map: TiledMap): TiledRenderorder {.inline.} = map.renderorder
proc width*         (map: TiledMap): int {.inline.} = map.width
proc height*        (map: TiledMap): int {.inline.} = map.height
proc tilewidth*     (map: TiledMap): int {.inline.} = map.tilewidth
proc tileheight*    (map: TiledMap): int {.inline.} = map.tileheight
proc infinite*      (map: TiledMap): bool {.inline.} = map.infinite
proc tilesets*      (map: TiledMap): seq[TiledTileset] {.inline.} = map.tilesets
proc layers*        (map: TiledMap): seq[TiledLayer] {.inline.} = map.layers
proc objectGroups*  (map: TiledMap): seq[TiledObjectGroup] {.inline.} = map.objectGroups

# Public properties for the TiledLayer
proc name*    (layer: TiledLayer): string {.inline.}= layer.name
proc width*   (layer: TiledLayer): int {.inline.}= layer.width
proc height*  (layer: TiledLayer): int {.inline.}= layer.height
proc tiles*   (layer: TiledLayer): seq[int] {.inline.}= layer.tiles

# Public properties for the TiledObjectGroup
proc objects*   (layer: TiledObjectGroup): seq[TiledObject] {.inline.}= layer.objects

# Public properties for the TiledTileset
proc name* (tileset: TiledTileset): string {.inline.}= tileset.name
proc imagePath* (tileset: TiledTileset): string {.inline.}= tileset.imagePath
proc tilewidth* (tileset: TiledTileset): int {.inline.}= tileset.tilewidth
proc tileheight* (tileset: TiledTileset): int {.inline.}= tileset.tileheight
proc firstgid* (tileset: TiledTileset): int {.inline.}= tileset.firstgid
proc width* (tileset: TiledTileset): int {.inline.}= tileset.width
proc height* (tileset: TiledTileset): int {.inline.}= tileset.height
proc tilecount* (tileset: TiledTileset): int {.inline.}= tileset.tilecount
proc columns* (tileset: TiledTileset): int {.inline.}= tileset.columns
proc regions* (tileset: TiledTileset): seq[TiledRegion] {.inline.}= tileset.regions
proc tiles* (tileset: TiledTileset): auto {.inline.}= tileset.tiles

# Public properties for the TiledRegion
proc x* (r: TiledRegion): auto {.inline.} = r.x
proc y* (r: TiledRegion): auto {.inline.} = r.y
proc width* (r: TiledRegion): auto {.inline.} = r.width
proc height* (r: TiledRegion): auto {.inline.} = r.height

# Public properties for the TiledObject
proc x* (r: TiledObject): auto {.inline.} = r.x
proc y* (r: TiledObject): auto {.inline.} = r.y
proc width* (r: TiledObject): auto {.inline.} = r.width
proc height* (r: TiledObject): auto {.inline.} = r.height
proc name* (r: TiledObject): auto {.inline.} = r.name
proc objectType* (r: TiledObject): auto {.inline.} = r.objectType
proc properties* (r: TiledObject): auto {.inline.} = r.properties

# Tiled Frame properties
proc tileid* (frame: TiledFrame): auto = frame.tileid
proc duration* (frame: TiledFrame): auto = frame.duration

# Tiled Tile properties
proc tileid* (tile: TiledTile): auto = tile.tileid
proc animation* (tile: TiledTile): auto = tile.animation

proc `$`* (o: TiledPolygon): auto=
  result = "TiledPolygon{\n"
  result &= "   x:" & $o.x & "\n"
  result &= "   y:" & $o.y & "\n"
  result &= "   width:" & $o.width & "\n"
  result &= "   height:" & $o.height & "\n"
  result &= "   points: ["
  for p in o.points:
    result &= fmt"({p[0]},{p[1]}),"
  result &= "]\n}"

proc `$`* (o: TiledPolyline): auto=
  result = "TiledPolyline{\n"
  result &= "   x:" & $o.x & "\n"
  result &= "   y:" & $o.y & "\n"
  result &= "   width:" & $o.width & "\n"
  result &= "   height:" & $o.height & "\n"
  result &= "   points: ["
  for p in o.points:
    result &= fmt"({p[0]},{p[1]}),"
  result &= "]\n}"

proc `$`* (o: TiledPoint): auto=
  result = "TiledPoint{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`* (o: TiledEllipse): auto=
  result = "TiledEllipse{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`* (o: TiledObject): auto=
  if o of TiledPoint: return $(o.TiledPoint)
  if o of TiledEllipse: return $(o.TiledEllipse)
  if o of TiledPolygon: return $(o.TiledPolygon)
  if o of TiledPolyline: return $(o.TiledPolyline)
  result = "TiledObject{x:"& $o.x & " y:" & $o.y & " width:" & $o.width & " height:" & $o.height & "}"

proc `$`* (f: TiledFrame): auto=
  result = "TiledFrame{tileid: " & $f.tileid & ", duration: " & $f.duration & "}"

proc `$`* (t: TiledTile): auto=
  result = "TiledTile{" & "\n"
  result &= "   tileid:" & $t.tileid & "\n"
  result &= "   animation: @[" & "\n"
  for frame in t.animation:
    result &= "      " & $frame & ",\n"
  result &= "   ]\n}"

proc `$`* (t: TiledTileset): auto=
  result  = "TiledTileset{\n"
  result &= "   name:" & t.name & "\n"
  result &= "   path:" & t.imagePath& "\n"
  result &= "   tilewidth:" & $t.tilewidth & "\n"
  result &= "   tileheight:" & $t.tileheight & "\n"
  result &= "   columns:" & $t.columns & "\n"
  result &= "   width:" & $t.width & "\n"
  result &= "   height:" & $t.height & "\n"
  result &= "}"

proc assertWarn(expression: bool, msg: string, color = true): bool=
  result = expression
  if not expression:
    if color:
     styledWriteLine(stdout, fgYellow, "[nim_tiled]::Warning:: ", resetStyle, msg)
    else:
      echo fmt"[nim_tiled]::Warning:: {msg}"

proc newTiledRegion* (x, y, width, height: int): TiledRegion=
    TiledRegion(x: x, y: y, width: width, height: height)

proc loadTileset* (theXml: XmlNode): TiledTileset=
  result = TiledTileset(
    tiles: newTable[int, TiledTile]()
  )

  result.name         = theXml.attr "name"
  result.tilewidth    = theXml.attr("tilewidth").parseInt
  result.tileheight   = theXml.attr("tileheight").parseInt
  result.tilecount    = theXml.attr("tilecount").parseInt
  result.columns      = theXml.attr("columns").parseInt

  let theImage = theXml[0]

  # Load tiles in the tileset
  var first = true
  for tile in theXml:
    if first: first = false; continue
    let tileid = tile.attr("id").parseInt
    let animation = tile[0]

    var tile = TiledTile(
      tileid: tileid,
      animation: @[])

    for frame in animation:
      var frame = TiledFrame(
        tileid: frame.attr("tileid").parseInt,
        duration: frame.attr("duration").parseInt)

      tile.animation.add(frame)
    result.tiles.add(tileid, tile)

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
    
proc loadTileset* (path: string): TiledTileset=
    ## This loads a tileset from disk, usually only called from the
    ## loadTiledmap procedure
    result = TiledTileset()

    if not assertWarn(fileExists path, fmt"cannot find tileset: {path}"):
      return

    let theXml = readFile(path)
        .newStringStream()
        .parseXml()

    result = loadTileset theXml

proc loadTiledMap* (path: string): TiledMap=
  
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

    result.infinite =
        if theXml.attr("infinite") == "0":
            false
        else:
            true
    
    if not assertWarn(result.infinite == false, fmt"Nim Tiled currently doesn't support infinite maps"):
      return

    let tileset_xmlnodes = theXml.findAll "tileset"
    for node in tileset_xmlnodes:
        let npath = node.attr("source")

        if npath == "":
          result.tilesets.add loadTileset(node)
        else:
          var tpath = npath
          #if parentDir(path) != parentDir(npath):
          tpath = parentDir(path) & "/" & node.attr("source")

          result.tilesets.add loadTileset(tpath)
    
    let layers_xmlnodes = theXml.findAll "layer"
    let objects_xmlnodes = theXml.findAll "objectgroup"

    for layerXml in layers_xmlnodes:
        let layer = TiledLayer(
            name: layerXml.attr "name",
            width: layerXml.attr("width").parseInt,
            height: layerXml.attr("height").parseInt,
        )

        layer.tiles = newSeq[int](layer.width * layer.height)

        let dataXml = layerXml[0][0]

        var encoding = "xml"
        if layerXml[0].attr("encoding") != "":
          encoding = layerXml[0].attr("encoding")

        case encoding
        of "csv":
          let dataText = dataXml.rawText
          let dataTextLen = dataText.len
          var cursor = 0
          var index = 0
          var token = ""

          while cursor < dataTextLen:
              cursor += parseUntil(dataText, token, ',', cursor) + 1
              token.removeSuffix()
              token.removePrefix()
              layer.tiles[index] = token.parseInt
              index += 1

        of "base64":
          let dataText = dataXml.rawText
          var compression = "none"
          if layerXml[0].attr("compression") != "":
            compression = layerXml[0].attr("compression")
          
          var decoded = dataText.strip()
          decoded = decode(decoded)
          case compression:
            of "gzip":
              decoded = uncompress(decoded, stream=GZIP_STREAM)
            of "zlib":
              decoded = uncompress(decoded, stream=ZLIB_STREAM)
            else:
              discard

          var seqOfChars = newSeq[char](decoded.len)
          var i = 0
          for c in decoded:
            seqOfChars[i] = c
            inc i

          let length = (decoded.len() / sizeof(int32)).int

          for i in 0..<length:
            let r = int8 seqOfChars[(i*sizeof(int32))+0]
            let g = int8 seqOfChars[(i*sizeof(int32))+1]
            let b = int8 seqOfChars[(i*sizeof(int32))+2]
            let a = int8 seqOfChars[(i*sizeof(int32))+3]
            var num: int32 = (a shl 24) or (b shl 16) or (g shl 8) or r

            layer.tiles[i] = int32 num
          
        of "xml":
          # XML
          #let dataText = dataXml.rawText
          #let dataTextLen = dataText.len
          #var cursor = 0
          #var index = 0
          #var token = ""

          #while cursor < dataTextLen:
              #cursor += parseUntil(dataText, token, ',', cursor) + 1
              #token.removeSuffix()
              #token.removePrefix()
              #layer.tiles[index] = token.parseInt
              #index += 1

          var index = 0
          for tile in layerXml[0]:
            var gid = 0
            if tile.attr("gid") != "":
              gid = tile.attr("gid").parseInt
            layer.tiles[index] = gid
            inc index
        else:
          echo "Nim Tiled does not support the encoding type: " & encoding
          return

        result.layers.add(layer)

    for objectsXml in objects_xmlnodes:
        discard """ TODO: Implement"""

        var objectGroup = TiledObjectGroup(objects: newSeq[TiledObject]())
        result.objectGroups.add objectGroup

        for objXml in objectsXml:
          let x = objXml.attr("x").parseFloat
          let y = objXml.attr("y").parseFloat

          var name = ""
          var otype = ""
          var width = 0.0
          var height = 0.0
          var rotation = 0.0

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

          var properties = newTable[string, TiledValue]()

          if objXml.child("properties") != nil:
            var propertiesXml = objXml.child "properties"

            for propXml in propertiesXml:
              let theTypeStr = propXml.attr("type")

              var str = propXml.attr("value")

              proc hexStringToColor(color_str: string): auto=
                let without_hash = color_str[1..len(color_str)-1]
                let a = without_hash[0..1].parseHexInt().float / 255.0
                let r = without_hash[2..3].parseHexInt().float / 255.0
                let g = without_hash[4..5].parseHexInt().float / 255.0
                let b = without_hash[6..7].parseHexInt().float / 255.0
                result = (r, g, b, a)

              let name = propXml.attr("name")
              properties[name] =
                case theTypeStr:
                  of "color": TiledValue(valueType: tvColor, valueColor: hexStringToColor(str))
                  of "float":
                    TiledValue(valueType: tvFloat, valueFloat: str.parseFloat)
                  of "int":
                    TiledValue(valueType: tvInt, valueInt: str.parseInt)
                  of "bool":
                    TiledValue(valueType: tvBool, valueBool: str == "true")
                  else:
                    TiledValue(valueType: tvString, valueString: str)

          var isRect = true
          for subXml in objXml:
            case subXml.tag:
              of "polygon":
                isRect = false

                let pointsStr = subXml.attr("points")
                let splits = pointsStr.split ' '

                var o = TiledPolygon(
                  x: x, y: y, width: width, height: height,
                  rotation: rotation,
                  points: newSeq[(float, float)](),
                  name: name,
                  objectType: otype,
                  properties: properties
                )

                for pstr in splits:
                   let p = pstr.split(',')
                   let x = p[0].parseFloat
                   let y = p[1].parseFloat
                   o.points.add (x, y)

                objectGroup.objects.add o

              of "polyline":
                isRect = false

                let pointsStr = subXml.attr("points")
                let splits = pointsStr.split ' '

                var o = TiledPolyline(
                  x: x, y: y, width: width, height: height,
                  rotation: rotation,
                  points: newSeq[(float, float)](),
                  name: name,
                  objectType: otype,
                  properties: properties
                )

                for pstr in splits:
                   let p = pstr.split(',')
                   let x = p[0].parseFloat
                   let y = p[1].parseFloat
                   o.points.add (x, y)

                objectGroup.objects.add o

              of "point":
                isRect = false

                var o = TiledPoint(
                  x: x,
                  y: y,
                  width: 0,
                  height: 0,
                  rotation: rotation,
                  name: name,
                  objectType: otype,
                  properties: properties)
                objectGroup.objects.add o

              of "ellipse":
                isRect = false

                var o = TiledEllipse(
                  x: x,
                  y: y,
                  width: width,
                  height: height,
                  rotation: rotation,
                  name: name,
                  objectType: otype,
                  properties: properties)
                objectGroup.objects.add o

              of "properties": discard
              else:
                echo fmt"Nim Tiled unsuported object type: {subXml.tag}"

          if isRect:
            var o = TiledObject(
                x: x, y: y, width: width, height: height,
                rotation: rotation,
                name: name,
                objectType: otype,
                properties: properties
              )

            objectGroup.objects.add(o)
