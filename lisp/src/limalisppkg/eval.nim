from ./read import nil
import tables, sets
from parseutils import nil

type
  CellKind* = enum
    Error,
    Long,
    Double,
    String,
    Fn,
    List,
    Vector,
    Map,
    Set,
  ErrorKind* = enum
    NotImplemented,
    InvalidToken,
    VarDoesNotExist,
    EmptyFnInvocation,
    NumberParseError,
    NotAFunction,
    InvalidType,
  Cell* = object
    case kind*: CellKind
    of Error:
      error*: ErrorKind
    of Long:
      longVal*: int64
    of Double:
      doubleVal*: float64
    of String:
      stringVal: string
    of Fn:
      fnVal*: proc (cells: seq[Cell]): Cell {.noSideEffect.}
    of List:
      listVal*: seq[Cell]
    of Vector:
      vectorVal*: seq[Cell]
    of Map:
      mapVal*: Table[Cell, Cell]
    of Set:
      setVal*: HashSet[Cell]
    readCell*: read.Cell
  Context* = object
    vars*: Table[string, Cell]

const
  delimToType = {
    "(": List,
    "[": Vector,
    "{": Map,
    "#{": Set,
  }.toTable

func `==`*(a, b: Cell): bool =
  if a.kind == b.kind:
    case a.kind:
    of Error:
      a.error == b.error
    of Long:
      a.longVal == b.longVal
    of Double:
      a.doubleVal == b.doubleVal
    of String:
      a.stringVal == b.stringVal
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

func isAllLongs(args: seq[Cell]): bool =
  for arg in args:
    if arg.kind != Long:
      return false
  true

func plus*(args: seq[Cell]): Cell =
  if isAllLongs(args):
    var res: int64 = 0
    for arg in args:
      res += arg.longVal
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = 0.0
    for arg in args:
      case arg.kind:
      of Long:
        res += arg.longVal.float64
      of Double:
        res += arg.doubleVal
      else:
        return Cell(kind: Error, error: InvalidType, readCell: arg.readCell)
    Cell(kind: Double, doubleVal: res)

func minus*(args: seq[Cell]): Cell =
  if isAllLongs(args):
    var res: int64 = 0
    var i = 0
    for arg in args:
      if i == 0:
        res = arg.longVal
      else:
        res -= arg.longVal
      i += 1
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = 0.0
    var i = 0
    for arg in args:
      case arg.kind:
      of Long:
        if i == 0:
          res = arg.longVal.float64
        else:
          res -= arg.longVal.float64
      of Double:
        if i == 0:
          res = arg.doubleVal
        else:
          res -= arg.doubleVal
      else:
        return Cell(kind: Error, error: InvalidType, readCell: arg.readCell)
      i += 1
    Cell(kind: Double, doubleVal: res)

func times*(args: seq[Cell]): Cell =
  if isAllLongs(args):
    var res: int64 = 1
    for arg in args:
      res *= arg.longVal
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = 1.0
    for arg in args:
      case arg.kind:
      of Long:
        res *= arg.longVal.float64
      of Double:
        res *= arg.doubleVal
      else:
        return Cell(kind: Error, error: InvalidType, readCell: arg.readCell)
    Cell(kind: Double, doubleVal: res)

func divide*(args: seq[Cell]): Cell =
  var res: float64 = 1.0
  var i = 0
  for arg in args:
    case arg.kind:
    of Long:
      if i == 0:
        res = arg.longVal.float64
      else:
        res /= arg.longVal.float64
    of Double:
      if i == 0:
        res = arg.doubleVal
      else:
        res /= arg.doubleVal
    else:
      return Cell(kind: Error, error: InvalidType, readCell: arg.readCell)
    i += 1
  Cell(kind: Double, doubleVal: res)

func initContext*(): Context =
  result.vars["+"] = Cell(kind: Fn, fnVal: plus)
  result.vars["-"] = Cell(kind: Fn, fnVal: minus)
  result.vars["*"] = Cell(kind: Fn, fnVal: times)
  result.vars["/"] = Cell(kind: Fn, fnVal: divide)

func invoke*(ctx: Context, fn: Cell, args: seq[Cell]): Cell =
  if fn.kind == Fn:
    fn.fnVal(args)
  else:
    Cell(kind: Error, error: NotAFunction, readCell: fn.readCell)

func eval*(ctx: Context, cell: read.Cell): Cell =
  if cell.error != read.None:
    return Cell(kind: Error, error: InvalidToken, readCell: cell)
  case cell.kind:
  of read.Collection:
    let delim = cell.delims[0].token
    let typ = delimToType[delim]
    case typ:
    of List:
      var cells: seq[Cell]
      for cell in cell.contents:
        let res = eval(ctx, cell)
        if res.kind == Error:
          return res
        else:
          cells.add(res)
      if cells.len > 0:
        return invoke(ctx, cells[0], cells[1 ..< cells.len])
      else:
        Cell(kind: Error, error: EmptyFnInvocation, readCell: cell)
    else:
      Cell(kind: Error, error: NotImplemented, readCell: cell)
  of read.Symbol:
    if cell.token in ctx.vars:
      var ret = ctx.vars[cell.token]
      ret.readCell = cell
      ret
    else:
      Cell(kind: Error, error: VarDoesNotExist, readCell: cell)
  of read.Number:
    var periodCount = 0
    for ch in cell.token:
      if ch == '.':
        periodCount += 1
    if periodCount == 0:
      var res: int
      try:
        parseutils.parseInt(cell.token, res)
      except ValueError:
        return Cell(kind: Error, error: NumberParseError, readCell: cell)
      Cell(kind: Long, longVal: res.int64, readCell: cell)
    elif periodCount == 1:
      var res: float
      try:
        parseutils.parseFloat(cell.token, res)
      except ValueError:
        return Cell(kind: Error, error: NumberParseError, readCell: cell)
      Cell(kind: Double, doubleVal: res.float64, readCell: cell)
    else:
      Cell(kind: Error, error: NumberParseError, readCell: cell)
  of read.String:
    Cell(kind: String, stringVal: cell.stringValue, readCell: cell)
  else:
    Cell(kind: Error, error: NotImplemented, readCell: cell)

func eval*(cell: read.Cell): Cell =
  var ctx = initContext()
  eval(ctx, cell)
