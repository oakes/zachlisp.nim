import unicode
import tables

type
  CellKind* = enum
    List,
    Vector,
    Map,
    Set,
    SpecialPair,
    Whitespace,
    OpenDelimiter,
    CloseDelimiter,
    Symbol,
    Number,
    Keyword,
    SpecialCharacter,
    SpecialSymbol,
    Comment,
    String,
    Character,
  ErrorKind* = enum
    None,
    NoMatchingOpenDelimiter,
    NoMatchingCloseDelimiter,
    InvalidDelimiter,
    NothingValidAfter,
    NoMatchingUnquote,
  Cell* = object
    case kind*: CellKind
    of List, Vector, Map, Set, SpecialPair:
      cells*: seq[Cell]
    else:
      token*: string
      position*: tuple[line: int, column: int]
    error*: ErrorKind

const
  openDelims = {'(', '[', '{'}
  closeDelims = {')', ']', '}'}
  digits = {'0'..'9'}
  whitespace = {' ', '\t', '\r', '\n', ','}
  hash = '#'
  colon = ':'
  specialCharacters = {'^', '\'', '`', '~', '@'}
  newline = '\n'
  semicolon = ';'
  doublequote = '"'
  backslash = '\\'
  underscore = '_'
  invalidAfterCharacter = {' ', '\t', '\r', '\n'}
  openList = "("
  openVector = "["
  openMap = "{"
  openSet = "#{"
  delimPairs = {
    openList: ")",
    openVector: "]",
    openMap: "}",
    openSet: "}",
  }.toTable
  emptyCell = Cell(kind: Whitespace, token: "")
  hashCell = Cell(kind: SpecialSymbol, token: $hash)

func `==`*(a, b: Cell): bool =
  if a.kind == b.kind:
    case a.kind:
    of List, Vector, Map, Set, SpecialPair:
      a.cells == b.cells and a.error == b.error
    else:
      a.token == b.token and a.error == b.error
  else:
    false

func lex*(code: string, discardTypes: set[CellKind] = {Whitespace}): seq[Cell] =
  var
    temp = emptyCell
    escaping = false
    line = 1
    column = 1

  proc flush(res: var seq[Cell]) =
    if temp != emptyCell and temp.kind notin discardTypes:
      res.add(temp)
    temp = emptyCell

  proc save(res: var seq[Cell], cell: Cell, compatibleTypes: set[CellKind]) =
    if temp.kind in compatibleTypes:
      temp.token &= cell.token
    else:
      flush(res)
      temp = cell

  for rune in code.runes:
    let
      str = $rune
      ch = str[0]
      esc = escaping
      position = (line: line, column: column)

    escaping = (not escaping and ch == backslash)

    if ch == newline:
      line += 1
      column = 1
    else:
      column += 1

    # deal with types that can contain a stream of arbitrary characters
    case temp.kind:
    of Character:
      if ch in invalidAfterCharacter or (ch == semicolon and temp.token.len > 1):
        if temp.token.len == 1:
          temp.error = NothingValidAfter
        flush(result)
      else:
        temp.token &= str
        continue
    of Comment:
      if ch != newline:
        temp.token &= str
        continue
    of String:
      temp.token &= str
      if ch == doublequote and not esc:
        flush(result)
      continue
    else:
      discard

    # fast path for ascii chars
    if str.len == 1:
      case ch:
      of openDelims:
        if temp == hashCell:
          temp = Cell(kind: OpenDelimiter, token: temp.token & str, position: temp.position)
        else:
          save(result, Cell(kind: OpenDelimiter, token: str, position: position), {})
        continue
      of closeDelims:
        save(result, Cell(kind: CloseDelimiter, token: str, position: position), {})
        continue
      of digits:
        save(result, Cell(kind: Number, token: str, position: position), {Number, Symbol, Keyword})
        continue
      of whitespace:
        save(result, Cell(kind: Whitespace, token: str, position: position), {Whitespace})
        continue
      of colon:
        save(result, Cell(kind: Keyword, token: str, position: position), {Keyword})
        continue
      of specialCharacters:
        save(result, Cell(kind: SpecialCharacter, token: str, position: position), {SpecialCharacter})
        continue
      of hash:
        save(result, Cell(kind: SpecialSymbol, token: str, position: position), {Symbol, Keyword})
        continue
      of semicolon:
        save(result, Cell(kind: Comment, token: str, position: position), {})
        continue
      of doublequote:
        save(result, Cell(kind: String, token: str, position: position), {})
        continue
      of backslash:
        save(result, Cell(kind: Character, token: str, position: position), {})
        continue
      of underscore:
        if temp == hashCell:
          temp = Cell(kind: SpecialSymbol, token: temp.token & str, position: position)
          flush(result)
          continue
      else:
        discard

    # all other chars
    save(result, Cell(kind: Symbol, token: str, position: position), {Symbol, Number, Keyword, SpecialSymbol})

  if temp.kind == String:
    temp.error = NoMatchingUnquote

  flush(result)

func parse*(cells: seq[Cell], index: var int): seq[Cell]

func parseCollection*(cells: seq[Cell], index: var int, delimiter: Cell): seq[Cell] =
  var coll =
    case delimiter.token:
    of openList:
      Cell(kind: List, cells: @[delimiter])
    of openVector:
      Cell(kind: Vector, cells: @[delimiter])
    of openMap:
      Cell(kind: Map, cells: @[delimiter])
    of openSet:
      Cell(kind: Set, cells: @[delimiter])
    else:
      Cell(kind: List, cells: @[delimiter], error: InvalidDelimiter)
  let closeDelim = delimPairs[delimiter.token]
  while index < cells.len:
    let cell = cells[index]
    case cell.kind:
    of CloseDelimiter:
      if cell.token == closeDelim:
        index += 1
        coll.cells.add(cell)
        return @[coll]
      else:
        coll.cells[0].error = NoMatchingCloseDelimiter
        return coll.cells
    else:
      coll.cells.add(parse(cells, index))
  coll.cells[0].error = NoMatchingCloseDelimiter
  coll.cells

func parse*(cells: seq[Cell], index: var int): seq[Cell] =
  if index == cells.len:
    return @[]

  let cell = cells[index]
  index += 1

  case cell.kind:
  of OpenDelimiter:
    parseCollection(cells, index, cell)
  of CloseDelimiter:
    var res = cell
    res.error = NoMatchingOpenDelimiter
    @[res]
  else:
    if cell.kind in {SpecialCharacter, SpecialSymbol}:
      if index < cells.len:
        let nextCells = parse(cells, index)
        if nextCells.len == 1 and nextCells[0].error == None:
          @[Cell(kind: SpecialPair, cells: @[cell] & nextCells)]
        else:
          index -= 1
          var res = cell
          res.error = NothingValidAfter
          @[res]
      else:
        var res = cell
        res.error = NothingValidAfter
        @[res]
    else:
      @[cell]

func parse*(cells: seq[Cell]): seq[Cell] =
  var index = 0
  while index < cells.len:
    result.add(parse(cells, index))

func read*(code: string): seq[Cell] =
  code.lex().parse()
