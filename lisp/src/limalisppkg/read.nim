import unicode, tables, sets

type
  CellKind* = enum
    Empty,
    Collection,
    SpecialPair,
    Whitespace,
    OpenDelimiter,
    CloseDelimiter,
    Symbol,
    Number,
    Keyword,
    SpecialCharacter,
    Comment,
    String,
    Character,
  ErrorKind* = enum
    None,
    NoMatchingOpenDelimiter,
    NoMatchingCloseDelimiter,
    MustHaveEvenNumberOfForms,
    NothingValidAfter,
    NoMatchingUnquote,
    InvalidEscape,
    InvalidDelimiter,
    InvalidKeyword,
  Position = tuple[line: int, column: int]
  Cell* = object
    case kind*: CellKind
    of Collection:
      delims*: seq[Cell]
      contents*: seq[Cell]
    of SpecialPair:
      pair*: seq[Cell]
    of String:
      stringValue*: string
      stringToken*: string
      stringPosition*: Position
    else:
      token*: string
      position*: Position
    error*: ErrorKind

const
  openDelims = {'(', '[', '{'}
  closeDelims = {')', ']', '}'}
  delimPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
  }.toTable
  validOpenDelims = ["(", "[", "{", "#{"].toHashSet
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
  emptyCell = Cell(kind: Whitespace, token: "")
  dispatchCell = Cell(kind: SpecialCharacter, token: $hash)

func `==`*(a, b: Cell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Collection:
      a.delims == b.delims and a.contents == b.contents and a.error == b.error
    of SpecialPair:
      a.pair == b.pair and a.error == b.error
    of String:
      a.stringToken == b.stringToken and a.error == b.error
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
      temp.stringToken &= str
      if ch == doublequote and not esc:
        var
          stresc = false
          str = ""
        for r in temp.stringToken[1 ..< temp.stringToken.len-1].runes:
          let s = $r
          if stresc:
            case s:
            of "\"", "\\":
              str &= s
            else:
              temp.error = InvalidEscape
          else:
            str &= s
          stresc = not stresc and s[0] == backslash
        temp.stringValue = str
        flush(result)
      continue
    else:
      discard

    # fast path for ascii chars
    if str.len == 1:
      case ch:
      of openDelims:
        save(result, Cell(kind: OpenDelimiter, token: str, position: position), {})
        continue
      of closeDelims:
        save(result, Cell(kind: CloseDelimiter, token: str, position: position), {})
        continue
      of digits:
        if temp.token == "-":
          temp = Cell(kind: Number, token: temp.token & str, position: temp.position)
        else:
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
        save(result, Cell(kind: SpecialCharacter, token: str, position: position), {Symbol, Keyword})
        continue
      of semicolon:
        save(result, Cell(kind: Comment, token: str, position: position), {})
        continue
      of doublequote:
        save(result, Cell(kind: String, stringToken: str, stringPosition: position), {})
        continue
      of backslash:
        save(result, Cell(kind: Character, token: str, position: position), {})
        continue
      of underscore:
        if temp == dispatchCell:
          temp = Cell(kind: SpecialCharacter, token: temp.token & str, position: position)
          flush(result)
          continue
      else:
        discard

    # all other chars
    save(result, Cell(kind: Symbol, token: str, position: position), {Symbol, Number, Keyword})

  if temp.kind == String:
    temp.error = NoMatchingUnquote

  flush(result)

func parse*(cells: seq[Cell], index: var int): seq[Cell]

func parseCollection*(cells: seq[Cell], index: var int, delimiter: Cell): seq[Cell] =
  var contents: seq[Cell] = @[]
  let closeDelim = delimPairs[delimiter.token[0]]
  while index < cells.len:
    let cell = cells[index]
    case cell.kind:
    of CloseDelimiter:
      if cell.token[0] == closeDelim:
        index += 1
        if delimiter.token[0] == '{' and contents.len mod 2 != 0:
          return @[Cell(kind: Collection, delims: @[delimiter, cell], contents: contents, error: MustHaveEvenNumberOfForms)]
        else:
          return @[Cell(kind: Collection, delims: @[delimiter, cell], contents: contents)]
      else:
        var delim = delimiter
        delim.error = NoMatchingCloseDelimiter
        return @[delim] & contents
    else:
      contents.add(parse(cells, index))
  var delim = delimiter
  delim.error = NoMatchingCloseDelimiter
  @[delim] & contents

func name*(s: string): string =
  var i = 0
  for ch in s:
    if ch == ':':
      i+=1
    else:
      break
  s[i ..< s.len]

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
  of Keyword:
    var res = cell
    if name(cell.token).len == 0:
      res.error = InvalidKeyword
    @[res]
  else:
    if cell.kind == SpecialCharacter:
      if index < cells.len:
        let nextCells = parse(cells, index)
        if nextCells.len == 1:
          let nextCell = nextCells[0]
          if cell.token[0] == hash and
              nextCell.kind == Collection and
              nextCell.error in {None, MustHaveEvenNumberOfForms}:
            var res = nextCells[0]
            res.delims[0].token = cell.token & res.delims[0].token
            if res.delims[0].token in validOpenDelims:
              # uneven number of forms is not an error if it's a set now
              res.error = None
            else:
              res.error = InvalidDelimiter
            return @[res]
          elif nextCell.error == None:
            return @[Cell(kind: SpecialPair, pair: @[cell, nextCell])]
        var res = cell
        res.error = NothingValidAfter
        @[res] & nextCells
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
