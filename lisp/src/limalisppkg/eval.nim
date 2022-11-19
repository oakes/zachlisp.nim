from ./read import nil
import tables, sets
from parseutils import nil
from math import nil

type
  CellKind* = enum
    Error,
    Boolean,
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
    InvalidNumberOfArguments,
  Cell* = object
    case kind*: CellKind
    of Error:
      error*: ErrorKind
    of Boolean:
      booleanVal*: bool
    of Long:
      longVal*: int64
    of Double:
      doubleVal*: float64
    of String:
      stringVal*: string
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
    of Boolean:
      a.booleanVal == b.booleanVal
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

func isAllLongs(args: seq[Cell]): bool =
  for arg in args:
    if arg.kind != Long:
      return false
  true

template toDouble(cell: Cell) =
  case cell.kind:
  of Long:
    cell.longVal.float64
  of Double:
    cell.doubleVal
  else:
    return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

template checkKind(cell: Cell, kinds: set[CellKind]) =
  if cell.kind notin kinds:
    return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

template checkKind(cells: seq[Cell], kinds: set[CellKind]) =
  for cell in cells:
    checkKind(cell, kinds)

template checkCount(count: int, min: int) =
  if count < min:
    return Cell(kind: Error, error: InvalidNumberOfArguments)

template checkCount(count: int, min: int, max: int) =
  checkCount(count, min)
  if count > max:
    return Cell(kind: Error, error: InvalidNumberOfArguments)

# public functions

func eq*(args: seq[Cell]): Cell =
  for i in 0 ..< args.len - 1:
    if args[i] != args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func ge*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] < args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func gt*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] <= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func le*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] > args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func lt*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] >= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func min*(args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg < res:
      res = arg
  res

func max*(args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg > res:
      res = arg
  res

func plus*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  if isAllLongs(args):
    var res: int64 = 0
    for arg in args:
      res += arg.longVal
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = 0.0
    for arg in args:
      res += arg.toDouble
    Cell(kind: Double, doubleVal: res)

func minus*(args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
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
      if i == 0:
        res = arg.toDouble
      else:
        res -= arg.toDouble
      i += 1
    Cell(kind: Double, doubleVal: res)

func times*(args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  if isAllLongs(args):
    var res: int64 = 1
    for arg in args:
      res *= arg.longVal
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = 1.0
    for arg in args:
      res *= arg.toDouble
    Cell(kind: Double, doubleVal: res)

func divide*(args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res: float64 = 1.0
  var i = 0
  for arg in args:
    if i == 0:
      res = arg.toDouble
    else:
      res /= arg.toDouble
    i += 1
  Cell(kind: Double, doubleVal: res)

func pow*(args: seq[Cell]): Cell =
  checkCount(args.len, 2, 2)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.pow(args[0].toDouble, args[1].toDouble))

func exp*(args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.exp(args[0].toDouble))

func floor*(args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.floor(args[0].toDouble))

func ceil*(args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.ceil(args[0].toDouble))

func initContext*(): Context =
  result.vars["="] = Cell(kind: Fn, fnVal: eq)
  result.vars[">"] = Cell(kind: Fn, fnVal: gt)
  result.vars[">="] = Cell(kind: Fn, fnVal: ge)
  result.vars["<"] = Cell(kind: Fn, fnVal: lt)
  result.vars["<="] = Cell(kind: Fn, fnVal: le)
  result.vars["min"] = Cell(kind: Fn, fnVal: min)
  result.vars["max"] = Cell(kind: Fn, fnVal: max)
  result.vars["+"] = Cell(kind: Fn, fnVal: plus)
  result.vars["-"] = Cell(kind: Fn, fnVal: minus)
  result.vars["*"] = Cell(kind: Fn, fnVal: times)
  result.vars["/"] = Cell(kind: Fn, fnVal: divide)
  result.vars["pow"] = Cell(kind: Fn, fnVal: pow)
  result.vars["exp"] = Cell(kind: Fn, fnVal: exp)
  result.vars["floor"] = Cell(kind: Fn, fnVal: floor)
  result.vars["ceil"] = Cell(kind: Fn, fnVal: ceil)

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
        var res = invoke(ctx, cells[0], cells[1 ..< cells.len])
        # set the readCell if it hasn't been set already
        if res.readCell.kind == read.Empty:
          res.readCell = cell
        res
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
