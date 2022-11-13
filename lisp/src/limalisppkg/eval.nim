from ./read import nil
import tables, sets
from parseutils import nil

type
  CellKind* = enum
    Error,
    Long,
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
    CantAddValue,
  Cell* = object
    case kind*: CellKind
    of Error:
      error*: ErrorKind
    of Long:
      longVal*: int64
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

func plus*(args: seq[Cell]): Cell =
  var res: int64
  for arg in args:
    case arg.kind:
    of Long:
      res += arg.longVal
    else:
      return Cell(kind: Error, error: CantAddValue, readCell: arg.readCell)
  Cell(kind: Long, longVal: res)

func initContext*(): Context =
  result.vars["+"] = Cell(kind: Fn, fnVal: plus)

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
    let typ = delimToType[cell.delims[0].token]
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
    var res: int
    try:
      parseutils.parseInt(cell.token, res)
    except ValueError:
      return Cell(kind: Error, error: NumberParseError, readCell: cell)
    Cell(kind: Long, longVal: res.int64, readCell: cell)
  of read.String:
    Cell(kind: String, stringVal: cell.stringValue, readCell: cell)
  else:
    Cell(kind: Error, error: NotImplemented, readCell: cell)

func eval*(cell: read.Cell): Cell =
  var ctx = initContext()
  eval(ctx, cell)
