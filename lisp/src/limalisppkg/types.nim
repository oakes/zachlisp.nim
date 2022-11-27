import tables, sets, hashes, unicode

type
  ReadCellKind* = enum
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
    MustReadEvenNumberOfForms,
    NothingValidAfter,
    NoMatchingUnquote,
    InvalidEscape,
    InvalidDelimiter,
    InvalidKeyword,
    InvalidSpecialLiteral,
    InvalidNumber,
  Token* = object
    value*: string
    position*: tuple[line: int, column: int]
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
    token*: Token
    error*: ReadErrorKind
  CellKind* = enum
    Error,
    Nil,
    Boolean,
    Long,
    Double,
    Character,
    Symbol
    String,
    Keyword,
    Fn,
    List,
    Vector,
    Map,
    Set,
  ErrorKind* = enum
    NotImplemented,
    InvalidToken,
    VarDoesNotExist,
    NumberParseError,
    NotAFunction,
    InvalidType,
    InvalidNumberOfArguments,
    MustHaveEvenNumberOfForms,
    IndexOutOfBounds,
    PrintLengthLimitExceeded,
  Cell* = object
    case kind*: CellKind
    of Error:
      error*: ErrorKind
    of Nil:
      discard
    of Boolean:
      booleanVal*: bool
    of Long:
      longVal*: int64
    of Double:
      doubleVal*: float64
    of Character:
      characterVal*: Rune
    of Symbol:
      symbolVal*: string
    of String:
      stringVal*: string
    of Keyword:
      keywordVal*: string
    of Fn:
      fnVal*: proc (ctx: Context, cells: seq[Cell]): Cell {.noSideEffect.}
      fnStringVal*: string
    of List:
      listVal*: seq[Cell]
    of Vector:
      vectorVal*: seq[Cell]
    of Map:
      mapVal*: Table[Cell, Cell]
    of Set:
      setVal*: HashSet[Cell]
    token*: Token
  Context* = object
    printLimit*: int
    vars*: Table[string, Cell]

func `==`*(a, b: ReadCell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Collection:
      a.delims == b.delims and a.contents == b.contents and a.error == b.error
    of SpecialPair:
      a.pair == b.pair and a.error == b.error
    else:
      a.token.value == b.token.value and a.error == b.error
  else:
    false

func name*(s: string): string =
  var i = 0
  for ch in s:
    if ch == ':':
      i+=1
    else:
      break
  s[i ..< s.len]

func hash*(a: Cell): Hash =
  case a.kind:
  of Error:
    a.error.hash
  of Nil:
    nil.hash
  of Boolean:
    a.booleanVal.hash
  of Long:
    a.longVal.hash
  of Double:
    a.doubleVal.hash
  of Character:
    a.characterVal.hash
  of Symbol:
    a.symbolVal.hash
  of String:
    a.stringVal.hash
  of Keyword:
    a.keywordVal.hash
  of Fn:
    a.fnVal.hash
  of List:
    a.listVal.hash
  of Vector:
    a.vectorVal.hash
  of Map:
    a.mapVal.hash
  of Set:
    a.setVal.hash

func `==`*(a, b: Cell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Error:
      a.error == b.error
    of Nil:
      true
    of Boolean:
      a.booleanVal == b.booleanVal
    of Long:
      a.longVal == b.longVal
    of Double:
      a.doubleVal == b.doubleVal
    of Character:
      a.characterVal == b.characterVal
    of Symbol:
      a.symbolVal == b.symbolVal
    of String:
      a.stringVal == b.stringVal
    of Keyword:
      a.keywordVal == b.keywordVal
    of Fn:
      a.fnVal == b.fnVal
    of List:
      a.listVal == b.listVal
    of Vector:
      a.vectorVal == b.vectorVal
    of Map:
      a.mapVal == b.mapVal
    of Set:
      a.setVal == b.setVal
  else:
    false

func `<`*(a, b: Cell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Long:
      a.longVal < b.longVal
    of Double:
      a.doubleVal < b.doubleVal
    else:
      false
  else:
    let
      f1 =
        case a.kind:
        of Long:
          a.longVal.float64
        of Double:
          a.doubleVal
        else:
          return false
      f2 =
        case b.kind:
        of Long:
          b.longVal.float64
        of Double:
          b.doubleVal
        else:
          return false
    f1 < f2

func `<=`*(a, b: Cell): bool =
  a < b or a == b
