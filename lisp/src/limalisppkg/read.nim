from ./types import ReadCell, ReadCellKind, ReadErrorKind, Cell, CellKind, Token, `==`
import unicode, tables, sets
from parseutils import nil

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
  period = '.'
  specialCharacters = {'^', '\'', '`', '~', '@'}
  newline = '\n'
  semicolon = ';'
  doublequote = '"'
  backslash = '\\'
  underscore = '_'
  invalidAfterCharacter = {' ', '\t', '\r', '\n'}
  emptyCell = ReadCell(kind: Whitespace, token: Token(value: ""))
  dispatchCell = ReadCell(kind: SpecialCharacter, token: Token(value: $hash))
  specialSyms = {
    "true": ReadCell(kind: Value, value: Cell(kind: Boolean, booleanVal: true), token: Token(value: "true")),
    "false": ReadCell(kind: Value, value: Cell(kind: Boolean, booleanVal: false), token: Token(value: "false")),
    "nil": ReadCell(kind: Value, value: Cell(kind: Nil), token: Token(value: "nil")),
  }.toTable

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
      temp.token.value &= cell.token.value
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
        temp.token.value &= str
        continue
    of Value:
      case temp.value.kind:
      of Character:
        if ch in invalidAfterCharacter or (ch == semicolon and temp.token.value.len > 1):
          if temp.token.value.len == 1:
            temp.error = NothingValidAfter
          flush(result)
        else:
          temp.token.value &= str
          continue
      of String:
        temp.token.value &= str
        if ch == doublequote and not esc:
          var
            stresc = false
            str = ""
          for r in temp.token.value[1 ..< temp.token.value.len-1].runes:
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
          temp.value.stringVal = str
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
        save(result, ReadCell(kind: OpenDelimiter, token: Token(value: str, position: position)), {}, {})
        continue
      of closeDelims:
        save(result, ReadCell(kind: CloseDelimiter, token: Token(value: str, position: position)), {}, {})
        continue
      of digits:
        if temp.token.value == "-":
          temp = ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: temp.token.value & str, position: temp.token.position))
        else:
          save(result, ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: str, position: position)), {}, {Long, Double, Symbol, Keyword})
        continue
      of period:
        if temp.kind == Value:
          case temp.value.kind:
          of Long:
            temp = ReadCell(kind: Value, value: Cell(kind: Double), token: Token(value: temp.token.value & str, position: temp.token.position))
            continue
          of Double:
            temp.token.value &= str
            temp.error = InvalidNumber
          else:
            discard
      of whitespace:
        save(result, ReadCell(kind: Whitespace, token: Token(value: str, position: position)), {Whitespace}, {})
        continue
      of colon:
        save(result, ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: str, position: position)), {}, {Symbol, Keyword})
        continue
      of specialCharacters:
        save(result, ReadCell(kind: SpecialCharacter, token: Token(value: str, position: position)), {SpecialCharacter}, {})
        continue
      of hash:
        save(result, ReadCell(kind: SpecialCharacter, token: Token(value: str, position: position)), {SpecialCharacter}, {Symbol, Keyword})
        continue
      of semicolon:
        save(result, ReadCell(kind: Comment, token: Token(value: str, position: position)), {}, {})
        continue
      of doublequote:
        save(result, ReadCell(kind: Value, value: Cell(kind: String), token: Token(value: str, position: position)), {}, {})
        continue
      of backslash:
        save(result, ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: str, position: position)), {}, {})
        continue
      of underscore:
        if temp == dispatchCell:
          temp = ReadCell(kind: SpecialCharacter, token: Token(value: temp.token.value & str, position: position))
          flush(result)
          continue
      else:
        discard

    # all other chars
    save(result, ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: str, position: position)), {}, {Symbol, Keyword, Long, Double})

  if temp.kind == Value and temp.value.kind == String:
    temp.error = NoMatchingUnquote

  flush(result)

func parse*(cells: seq[ReadCell], index: var int): seq[ReadCell]

func parseCollection*(cells: seq[ReadCell], index: var int, delimiter: ReadCell): seq[ReadCell] =
  var contents: seq[ReadCell] = @[]
  let closeDelim = delimPairs[delimiter.token.value[0]]
  while index < cells.len:
    let cell = cells[index]
    case cell.kind:
    of CloseDelimiter:
      if cell.token.value[0] == closeDelim:
        index += 1
        if delimiter.token.value[0] == '{' and contents.len mod 2 != 0:
          return @[ReadCell(kind: Collection, delims: @[delimiter, cell], contents: contents, error: MustReadEvenNumberOfForms)]
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
        if cell.token.value[0] == hash and
            nextCell.kind == Collection and
            nextCell.error in {None, MustReadEvenNumberOfForms}:
          var res = nextCells[0]
          res.delims[0].token.value = cell.token.value & res.delims[0].token.value
          if res.delims[0].token.value in validOpenDelims:
            # uneven number of forms is not an error if it's a set now
            res.error = None
          else:
            res.error = InvalidDelimiter
          return @[res]
        elif nextCell.error == None:
          if cell.token.value == "##":
            case nextCell.token.value:
            of "NaN":
              return @[ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "##NaN", position: cell.token.position))]
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
      if cell.token.value in specialSyms:
        @[specialSyms[cell.token.value]]
      else:
        @[cell]
    of Keyword:
      var res = cell
      res.value.keywordVal = cell.token.value
      if types.name(cell.token.value).len == 0:
        res.error = InvalidKeyword
      @[res]
    of Boolean:
      var res = cell
      res.value.booleanVal = cell.token.value == "true"
      @[res]
    of Long:
      var res = cell
      try:
        var n: int
        discard parseutils.parseInt(cell.token.value, n)
        res.value.longVal = n.int64
      except ValueError:
        res.error = InvalidNumber
      @[res]
    of Double:
      var res = cell
      try:
        var n: float
        discard parseutils.parseFloat(cell.token.value, n)
        res.value.doubleVal = n.float64
      except ValueError:
        res.error = InvalidNumber
      @[res]
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
