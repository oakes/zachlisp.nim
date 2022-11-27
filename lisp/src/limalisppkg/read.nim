import unicode, tables, sets

type
  CellKind* = enum
    Symbol,
    Nil,
    Boolean,
    Number,
    Keyword,
    String,
    Character,
  Cell* = object
    case kind*: CellKind
    of String:
      stringValue*: string
    else:
      discard
  ReadCellKind* = enum
    Empty,
    Collection,
    SpecialPair,
    SpecialCharacter,
    Whitespace,
    Comment,
    OpenDelimiter,
    CloseDelimiter,
    Value,
  ReadErrorKind* = enum
    None,
    NoMatchingOpenDelimiter,
    NoMatchingCloseDelimiter,
    MustHaveEvenNumberOfForms,
    NothingValidAfter,
    NoMatchingUnquote,
    InvalidEscape,
    InvalidDelimiter,
    InvalidKeyword,
    InvalidSpecialLiteral,
  Position = tuple[line: int, column: int]
  ReadCell* = object
    case kind*: ReadCellKind
    of Collection:
      delims*: seq[ReadCell]
      contents*: seq[ReadCell]
    of SpecialPair:
      pair*: seq[ReadCell]
    of Value:
      value*: Cell
    else:
      discard
    token*: string
    position*: Position
    error*: ReadErrorKind

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
  emptyCell = ReadCell(kind: Whitespace, token: "")
  dispatchCell = ReadCell(kind: SpecialCharacter, token: $hash)
  specialSyms = {
    "true": ReadCell(kind: Value, value: Cell(kind: Boolean), token: "true"),
    "false": ReadCell(kind: Value, value: Cell(kind: Boolean), token: "false"),
    "nil": ReadCell(kind: Value, value: Cell(kind: Nil), token: "nil"),
  }.toTable

func `==`*(a, b: ReadCell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Collection:
      a.delims == b.delims and a.contents == b.contents and a.error == b.error
    of SpecialPair:
      a.pair == b.pair and a.error == b.error
    else:
      a.token == b.token and a.error == b.error
  else:
    false

func lex*(code: string, discardTypes: set[ReadCellKind] = {Whitespace}): seq[ReadCell] =
  var
    temp = emptyCell
    escaping = false
    line = 1
    column = 1

  proc flush(res: var seq[ReadCell]) =
    if temp != emptyCell and temp.kind notin discardTypes:
      res.add(temp)
    temp = emptyCell

  proc save(res: var seq[ReadCell], cell: ReadCell, compatibleTypes: set[ReadCellKind], compatibleValueTypes: set[CellKind]) =
    if temp.kind in compatibleTypes or (temp.kind == Value and temp.value.kind in compatibleValueTypes):
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
    of Comment:
      if ch != newline:
        temp.token &= str
        continue
    of Value:
      case temp.value.kind:
      of Character:
        if ch in invalidAfterCharacter or (ch == semicolon and temp.token.len > 1):
          if temp.token.len == 1:
            temp.error = NothingValidAfter
          flush(result)
        else:
          temp.token &= str
          continue
      of String:
        temp.token &= str
        if ch == doublequote and not esc:
          var
            stresc = false
            str = ""
          for r in temp.token[1 ..< temp.token.len-1].runes:
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
          temp.value.stringValue = str
          flush(result)
        continue
      else:
        discard
    else:
      discard

    # fast path for ascii chars
    if str.len == 1:
      case ch:
      of openDelims:
        save(result, ReadCell(kind: OpenDelimiter, token: str, position: position), {}, {})
        continue
      of closeDelims:
        save(result, ReadCell(kind: CloseDelimiter, token: str, position: position), {}, {})
        continue
      of digits:
        if temp.token == "-":
          temp = ReadCell(kind: Value, value: Cell(kind: Number), token: temp.token & str, position: temp.position)
        else:
          save(result, ReadCell(kind: Value, value: Cell(kind: Number), token: str, position: position), {}, {Number, Symbol})
        continue
      of whitespace:
        save(result, ReadCell(kind: Whitespace, token: str, position: position), {Whitespace}, {})
        continue
      of specialCharacters:
        save(result, ReadCell(kind: SpecialCharacter, token: str, position: position), {SpecialCharacter}, {})
        continue
      of hash:
        save(result, ReadCell(kind: SpecialCharacter, token: str, position: position), {SpecialCharacter}, {Symbol})
        continue
      of semicolon:
        save(result, ReadCell(kind: Comment, token: str, position: position), {}, {})
        continue
      of doublequote:
        save(result, ReadCell(kind: Value, value: Cell(kind: String), token: str, position: position), {}, {})
        continue
      of backslash:
        save(result, ReadCell(kind: Value, value: Cell(kind: Character), token: str, position: position), {}, {})
        continue
      of underscore:
        if temp == dispatchCell:
          temp = ReadCell(kind: SpecialCharacter, token: temp.token & str, position: position)
          flush(result)
          continue
      else:
        discard

    # all other chars
    save(result, ReadCell(kind: Value, value: Cell(kind: Symbol), token: str, position: position), {}, {Symbol, Number})

  if temp.kind == Value and temp.value.kind == String:
    temp.error = NoMatchingUnquote

  flush(result)

func parse*(cells: seq[ReadCell], index: var int): seq[ReadCell]

func parseCollection*(cells: seq[ReadCell], index: var int, delimiter: ReadCell): seq[ReadCell] =
  var contents: seq[ReadCell] = @[]
  let closeDelim = delimPairs[delimiter.token[0]]
  while index < cells.len:
    let cell = cells[index]
    case cell.kind:
    of CloseDelimiter:
      if cell.token[0] == closeDelim:
        index += 1
        if delimiter.token[0] == '{' and contents.len mod 2 != 0:
          return @[ReadCell(kind: Collection, delims: @[delimiter, cell], contents: contents, error: MustHaveEvenNumberOfForms)]
        else:
          return @[ReadCell(kind: Collection, delims: @[delimiter, cell], contents: contents)]
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
    if ch == colon:
      i+=1
    else:
      break
  s[i ..< s.len]

func parse*(cells: seq[ReadCell], index: var int): seq[ReadCell] =
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
  of SpecialCharacter:
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
          if cell.token == "##":
            case nextCell.token:
            of "NaN":
              return @[ReadCell(kind: Value, value: Cell(kind: Symbol), token: "##NaN", position: cell.position)]
            else:
              return @[ReadCell(kind: SpecialPair, pair: @[cell, nextCell], error: InvalidSpecialLiteral)]
          else:
            return @[ReadCell(kind: SpecialPair, pair: @[cell, nextCell])]
      var res = cell
      res.error = NothingValidAfter
      @[res] & nextCells
    else:
      var res = cell
      res.error = NothingValidAfter
      @[res]
  of Value:
    case cell.value.kind:
    of Symbol:
      if cell.token in specialSyms:
        @[specialSyms[cell.token]]
      elif cell.token[0] == colon:
        var res = ReadCell(kind: Value, value: Cell(kind: Keyword), token: cell.token)
        if name(res.token).len == 0:
          res.error = InvalidKeyword
        @[res]
      else:
        @[cell]
    else:
      @[cell]
  else:
    @[cell]

func parse*(cells: seq[ReadCell]): seq[ReadCell] =
  var index = 0
  while index < cells.len:
    result.add(parse(cells, index))

func read*(code: string): seq[ReadCell] =
  code.lex().parse()
