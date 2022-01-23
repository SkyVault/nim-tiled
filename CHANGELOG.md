## [Unreleased]

* Removed getters for public properties.

* Fixed a bug where a tileset's `firstgid` wouldn't be set if the tileset was loaded from an external file

* Fixed a typo causing the map's orientation to _always_ be `Orthogonal`

* Added `tileType: string` field to tiles

* Added `properties` to maps, tilesets and tiles

* Renamed `valueType: TiledValueType` to `kind: TiledValueKind`

* Added `tvObject` value kind which represents a link to another object in the same map.

* Added `TiledGid` type, which is a global tile ID with flipping flags (`hflip`, `vflip`, and `dflip`)

* Added `findTilesetByGid` procedure

* Changed map data to an array of `TiledGid`s instead of `int`s

* Changed `TiledObject` to a variant type

* Added `tkTile` object kind, which is now the only one to have a `gid` field. These may be flipped, and inherit their `properties` from the attached tile.

* Renamed `TiledTileCollisionShape` to `TiledCollisionShape` and changed it to a variant type.

* Added ellipse collision shape


## [1.2.5] - 2021-12-29

* Added `gid` to `TiledObject`


## [1.2.4] - 2021-12-09

* Added support for tile collision shapes

* Added support for polygon objects

* Added `name` field to `ObjectGroup`

* Skip tiles that don't have an ID attribute


## [1.2.3] - 2021-12-03

* Removed zlib dependency, switched to pure nim `zippy`