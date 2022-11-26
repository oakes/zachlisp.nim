from ./read import nil
import tables, sets, hashes
from parseutils import nil
from math import nil

type
  CellKind* = enum
    Error,
    Nil,
    Boolean,
    Long,
    Double,
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
    readCell*: read.Cell
  Context* = object
    printLimit*: int
    vars*: Table[string, Cell]

const
  delimToType = {
    "(": List,
    "[": Vector,
    "{": Map,
    "#{": Set,
  }.toTable
  printLimit = 10000

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

template evalCells(ctx: Context, readCells: seq[read.Cell]): seq[Cell] =
  var cells: seq[Cell]
  for cell in readCells:
    let res = eval(ctx, cell)
    if res.kind == Error:
      return res
    else:
      cells.add(res)
  cells

template toSeq(cell: Cell): untyped =
  case cell.kind:
  of List:
    cell.listVal
  of Vector:
    cell.vectorVal
  of Map:
    var s: seq[Cell]
    for (k, v) in cell.mapVal.pairs:
      s.add(Cell(kind: Vector, vectorVal: @[k, v]))
    s
  of Set:
    var s: seq[Cell]
    for v in cell.setVal.items:
      s.add(v)
    s
  of Nil:
    newSeq[Cell]()
  else:
    return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func nilPun(cell: Cell): Cell =
  if cell.kind == Nil:
    Cell(kind: Vector, vectorVal: @[])
  else:
    cell

# public functions

func eq*(ctx: Context, args: seq[Cell]): Cell =
  for i in 0 ..< args.len - 1:
    if args[i] != args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func ge*(ctx: Context, args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] < args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func gt*(ctx: Context, args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] <= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func le*(ctx: Context, args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] > args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func lt*(ctx: Context, args: seq[Cell]): Cell =
  checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] >= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func min*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg < res:
      res = arg
  res

func max*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg > res:
      res = arg
  res

func plus*(ctx: Context, args: seq[Cell]): Cell =
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

func minus*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  if isAllLongs(args):
    var res: int64 = args[0].longVal
    for arg in args[1 ..< args.len]:
      res -= arg.longVal
    Cell(kind: Long, longVal: res)
  else:
    var res: float64 = args[0].toDouble
    for arg in args[1 ..< args.len]:
      res -= arg.toDouble
    Cell(kind: Double, doubleVal: res)

func times*(ctx: Context, args: seq[Cell]): Cell =
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

func divide*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {Long, Double})
  var res: float64 = args[0].toDouble
  for arg in args[1 ..< args.len]:
    res /= arg.toDouble
  Cell(kind: Double, doubleVal: res)

func pow*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 2, 2)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.pow(args[0].toDouble, args[1].toDouble))

func exp*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.exp(args[0].toDouble))

func floor*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.floor(args[0].toDouble))

func ceil*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.ceil(args[0].toDouble))

func sqrt*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.sqrt(args[0].toDouble))

func abs*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  let arg = args[0]
  if arg.kind == Long:
    Cell(kind: Long, longVal: abs(arg.longVal))
  else:
    Cell(kind: Double, doubleVal: abs(arg.toDouble))

func signum*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long, Double})
  let arg = args[0]
  if arg.kind == Long:
    Cell(kind: Long, longVal: math.sgn(arg.longVal))
  else:
    Cell(kind: Long, longVal: math.sgn(arg.toDouble))

func inc*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long})
  Cell(kind: Long, longVal: args[0].longVal + 1)

func dec*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  checkKind(args, {Long})
  Cell(kind: Long, longVal: args[0].longVal - 1)

func vec*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  checkKind(cell, {List, Vector, Map, Set})
  Cell(kind: Vector, vectorVal: toSeq(cell))

func nth*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 2, 2)
  let cell = args[0].nilPun
  checkKind(cell, {List, Vector, Map, Set})
  checkKind(args[1], {Long})
  let index = args[1].longVal
  case cell.kind:
  of List:
    if cell.listVal.len > index:
      cell.listVal[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of Vector:
    if cell.vectorVal.len > index:
      cell.vectorVal[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of Map:
    # TODO: make this more efficient
    var s: seq[Cell]
    for (k, v) in cell.mapVal.pairs:
      s.add(Cell(kind: Vector, vectorVal: @[k, v]))
    if s.len > index:
      s[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of Set:
    # TODO: make this more efficient
    var s: seq[Cell]
    for v in cell.setVal.items:
      s.add(v)
    if s.len > index:
      s[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func count*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  checkKind(cell, {List, Vector, Map, Set})
  case cell.kind:
  of List:
    Cell(kind: Long, longVal: cell.listVal.len)
  of Vector:
    Cell(kind: Long, longVal: cell.vectorVal.len)
  of Map:
    Cell(kind: Long, longVal: cell.mapVal.len)
  of Set:
    Cell(kind: Long, longVal: cell.setVal.len)
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func print(cell: Cell, shouldEscape: bool, limit: var int): Cell

template printCell(cell: Cell, limit: var int): untyped =
  let printedCell = print(cell, true, limit)
  if printedCell.kind == Error:
    return printedCell
  printedCell.stringVal

template printCells(cells: seq[Cell], limit: var int): untyped =
  var baseCell = Cell(kind: String, stringVal: "")
  var i = 0
  for cell in cells:
    baseCell.stringVal &= printCell(cell, limit)
    if i + 1 < cells.len:
      baseCell.stringVal &= " "
    i += 1
  baseCell.stringVal

template printCells(cells: Table[Cell, Cell], limit: var int): untyped =
  var baseCell = Cell(kind: String, stringVal: "")
  var i = 0
  for (k, v) in cells.pairs:
    baseCell.stringVal &= printCell(k, limit) & " " & printCell(v, limit)
    if i + 1 < cells.len:
      baseCell.stringVal &= " "
    i += 1
  baseCell.stringVal

template printCells(cells: HashSet[Cell], limit: var int): untyped =
  var baseCell = Cell(kind: String, stringVal: "")
  var i = 0
  for cell in cells:
    baseCell.stringVal &= printCell(cell, limit)
    if i + 1 < cells.len:
      baseCell.stringVal &= " "
    i += 1
  baseCell.stringVal

template toString[T](val: T, limit: var int): Cell =
  let s = $val
  limit -= s.len
  if limit < 0:
    Cell(kind: Error, error: PrintLengthLimitExceeded)
  else:
    Cell(kind: String, stringVal: s)

func print(cell: Cell, shouldEscape: bool, limit: var int): Cell =
  case cell.kind:
  of Error:
    cell
  of Nil:
    if shouldEscape:
      "nil".toString(limit)
    else:
      "".toString(limit)
  of Boolean:
    cell.booleanVal.toString(limit)
  of Long:
    cell.longVal.toString(limit)
  of Double:
    cell.doubleVal.toString(limit)
  of String:
    if shouldEscape:
      var s = ""
      for ch in cell.stringVal:
        addEscapedChar(s, ch)
      s = "\"" & s & "\""
      s.toString(limit)
    else:
      cell.readCell.stringValue.toString(limit)
  of Keyword:
    cell.keywordVal.toString(limit)
  of Fn:
    cell.fnStringVal.toString(limit)
  of List:
    limit -= 2
    Cell(kind: String, stringVal: "(" & printCells(cell.listVal, limit) & ")")
  of Vector:
    limit -= 2
    Cell(kind: String, stringVal: "[" & printCells(cell.vectorVal, limit) & "]")
  of Map:
    limit -= 2
    Cell(kind: String, stringVal: "{" & printCells(cell.mapVal, limit) & "}")
  of Set:
    limit -= 3
    Cell(kind: String, stringVal: "#{" & printCells(cell.setVal, limit) & "}")

func print*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  var limit = ctx.printLimit
  print(args[0], true, limit)

func str*(ctx: Context, args: seq[Cell]): Cell =
  var
    limit = ctx.printLimit
    retCell = Cell(kind: String, stringVal: "")
  for cell in args:
    let printedCell = print(cell, false, limit)
    if printedCell.kind == Error:
      return printedCell
    retCell.stringVal &= printedCell.stringVal
  retCell

func name*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0]
  checkKind(cell, {String, Keyword}) # TODO: support symbols
  case cell.kind:
  of String:
    cell
  of Keyword:
    Cell(kind: String, stringVal: read.name(cell.keywordVal))
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func conj(cell: Cell, contents: seq[Cell]): Cell =
  var res = cell
  case cell.kind:
  of List:
    for arg in contents:
      res.listVal = @[arg] & res.listVal
  of Vector:
    res.vectorVal &= contents
  of Map:
    for arg in contents:
      if arg.kind == Vector and arg.vectorVal.len == 2:
        let
          k = arg.vectorVal[0]
          v = arg.vectorVal[1]
        res.mapVal[k] = v
  of Set:
    for arg in contents:
      res.setVal.incl(arg)
  else:
    return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)
  res

func conj*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 2)
  let cell = args[0].nilPun
  checkKind(cell, {List, Vector, Map, Set})
  conj(cell, args[1 ..< args.len])

func cons*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 2)
  let lastCell = args[args.len-1].nilPun
  checkKind(lastCell, {List, Vector, Map, Set})
  Cell(kind: List, listVal: args[0 ..< args.len-1] & toSeq(lastCell))

func list*(ctx: Context, args: seq[Cell]): Cell =
  Cell(kind: List, listVal: args)

func get*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 2, 3)
  let
    cell = args[0].nilPun
    key = args[1]
    notFound =
      if args.len == 3:
        args[2]
      else:
        Cell(kind: Nil)
  checkKind(cell, {List, Vector, Map, Set})
  case cell.kind:
  of List:
    if key.kind == Long and cell.listVal.len > key.longVal:
      cell.listVal[key.longVal]
    else:
      notFound
  of Vector:
    if key.kind == Long and cell.vectorVal.len > key.longVal:
      cell.vectorVal[key.longVal]
    else:
      notFound
  of Map:
    if key in cell.mapVal:
      cell.mapVal[key]
    else:
      notFound
  of Set:
    if key in cell.setVal:
      Cell(kind: Boolean, booleanVal: true)
    else:
      Cell(kind: Boolean, booleanVal: false)
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func boolean*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Boolean:
    cell
  of Nil:
    Cell(kind: Boolean, booleanVal: false)
  else:
    Cell(kind: Boolean, booleanVal: true)

func long*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Long:
    cell
  of Double:
    Cell(kind: Long, longVal: cell.doubleVal.int64)
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func double*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Double:
    cell
  of Long:
    Cell(kind: Double, doubleVal: cell.longVal.float64)
  else:
    Cell(kind: Error, error: InvalidType, readCell: cell.readCell)

func concat*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  checkKind(args, {List, Vector, Map, Set, Nil})
  var ret = Cell(kind: Nil)
  for cell in args:
    case ret.kind:
    of Nil:
      case cell.kind:
      of List:
        ret = cell
      of Nil:
        continue
      else:
        ret = Cell(kind: Vector, vectorVal: toSeq(cell))
    of List:
      ret.listVal &= toSeq(cell)
    of Vector:
      ret.vectorVal &= toSeq(cell)
    else:
      return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)
  ret

func assoc*(ctx: Context, args: seq[Cell]): Cell =
  checkCount(args.len, 1)
  var cell =
    if args[0].kind == Nil:
      Cell(kind: Map)
    else:
      args[0]
  checkKind(cell, {List, Vector, Map})
  let cells = args[1 ..< args.len]
  if cells.len mod 2 != 0:
    return Cell(kind: Error, error: InvalidNumberOfArguments)
  var pairs: seq[(Cell, Cell)] = @[]
  for i in 0 ..< int(cells.len / 2):
    pairs.add((cells[i*2], cells[i*2+1]))
  for (key, val) in pairs:
    case cell.kind:
    of List:
      if key.kind != Long:
        return Cell(kind: Error, error: InvalidType, readCell: key.readCell)
      elif cell.listVal.len <= key.longVal:
        return Cell(kind: Error, error: IndexOutOfBounds, readCell: key.readCell)
      cell.listVal[key.longVal] = val
    of Vector:
      if key.kind != Long:
        return Cell(kind: Error, error: InvalidType, readCell: key.readCell)
      elif cell.vectorVal.len <= key.longVal:
        return Cell(kind: Error, error: IndexOutOfBounds, readCell: key.readCell)
      cell.vectorVal[key.longVal] = val
    of Map:
      cell.mapVal[key] = val
    else:
      return Cell(kind: Error, error: InvalidType, readCell: cell.readCell)
  cell

func initContext*(): Context =
  result.printLimit = printLimit
  result.vars["="] = Cell(kind: Fn, fnVal: eq, fnStringVal: "=")
  result.vars[">"] = Cell(kind: Fn, fnVal: gt, fnStringVal: ">")
  result.vars[">="] = Cell(kind: Fn, fnVal: ge, fnStringVal: ">=")
  result.vars["<"] = Cell(kind: Fn, fnVal: lt, fnStringVal: "<")
  result.vars["<="] = Cell(kind: Fn, fnVal: le, fnStringVal: "<=")
  result.vars["min"] = Cell(kind: Fn, fnVal: min, fnStringVal: "min")
  result.vars["max"] = Cell(kind: Fn, fnVal: max, fnStringVal: "max")
  result.vars["+"] = Cell(kind: Fn, fnVal: plus, fnStringVal: "+")
  result.vars["-"] = Cell(kind: Fn, fnVal: minus, fnStringVal: "-")
  result.vars["*"] = Cell(kind: Fn, fnVal: times, fnStringVal: "*")
  result.vars["/"] = Cell(kind: Fn, fnVal: divide, fnStringVal: "/")
  result.vars["pow"] = Cell(kind: Fn, fnVal: pow, fnStringVal: "pow")
  result.vars["exp"] = Cell(kind: Fn, fnVal: exp, fnStringVal: "exp")
  result.vars["floor"] = Cell(kind: Fn, fnVal: floor, fnStringVal: "floor")
  result.vars["ceil"] = Cell(kind: Fn, fnVal: ceil, fnStringVal: "ceil")
  result.vars["sqrt"] = Cell(kind: Fn, fnVal: sqrt, fnStringVal: "sqrt")
  result.vars["abs"] = Cell(kind: Fn, fnVal: abs, fnStringVal: "abs")
  result.vars["signum"] = Cell(kind: Fn, fnVal: signum, fnStringVal: "signum")
  result.vars["inc"] = Cell(kind: Fn, fnVal: inc, fnStringVal: "inc")
  result.vars["dec"] = Cell(kind: Fn, fnVal: dec, fnStringVal: "dec")
  result.vars["vec"] = Cell(kind: Fn, fnVal: vec, fnStringVal: "vec")
  result.vars["nth"] = Cell(kind: Fn, fnVal: nth, fnStringVal: "nth")
  result.vars["count"] = Cell(kind: Fn, fnVal: count, fnStringVal: "count")
  result.vars["print"] = Cell(kind: Fn, fnVal: print, fnStringVal: "print")
  result.vars["str"] = Cell(kind: Fn, fnVal: str, fnStringVal: "str")
  result.vars["name"] = Cell(kind: Fn, fnVal: name, fnStringVal: "name")
  result.vars["conj"] = Cell(kind: Fn, fnVal: conj, fnStringVal: "conj")
  result.vars["cons"] = Cell(kind: Fn, fnVal: cons, fnStringVal: "cons")
  result.vars["list"] = Cell(kind: Fn, fnVal: list, fnStringVal: "list")
  result.vars["get"] = Cell(kind: Fn, fnVal: get, fnStringVal: "get")
  result.vars["boolean"] = Cell(kind: Fn, fnVal: boolean, fnStringVal: "boolean")
  result.vars["long"] = Cell(kind: Fn, fnVal: long, fnStringVal: "long")
  result.vars["double"] = Cell(kind: Fn, fnVal: double, fnStringVal: "double")
  result.vars["concat"] = Cell(kind: Fn, fnVal: concat, fnStringVal: "concat")
  result.vars["assoc"] = Cell(kind: Fn, fnVal: assoc, fnStringVal: "assoc")

func invoke*(ctx: Context, fn: Cell, args: seq[Cell]): Cell =
  if fn.kind == Fn:
    fn.fnVal(ctx, args)
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
      let cells = evalCells(ctx, cell.contents)
      if cells.len > 0:
        var res = invoke(ctx, cells[0], cells[1 ..< cells.len])
        # set the readCell if it hasn't been set already
        if res.readCell.kind == read.Empty:
          res.readCell = cell
        res
      else:
        Cell(kind: List, listVal: @[], readCell: cell)
    of Vector:
      Cell(kind: Vector, vectorVal: evalCells(ctx, cell.contents))
    of Map:
      if cell.contents.len mod 2 != 0:
        return Cell(kind: Error, error: MustHaveEvenNumberOfForms, readCell: cell)
      let cells = evalCells(ctx, cell.contents)
      var t: Table[Cell, Cell]
      for i in 0 ..< int(cells.len / 2):
        t[cells[i*2]] = cells[i*2+1]
      Cell(kind: Map, mapVal: t)
    of Set:
      var hs: HashSet[Cell]
      for cell in evalCells(ctx, cell.contents):
        hs.incl(cell)
      Cell(kind: Set, setVal: hs)
    else:
      Cell(kind: Error, error: NotImplemented, readCell: cell)
  of read.Symbol:
    if cell.token in ctx.vars:
      var ret = ctx.vars[cell.token]
      ret.readCell = cell
      ret
    else:
      Cell(kind: Error, error: VarDoesNotExist, readCell: cell)
  of read.Nil:
    Cell(kind: Nil)
  of read.Boolean:
    Cell(kind: Boolean, booleanVal: cell.token == "true")
  of read.Number:
    var periodCount = 0
    for ch in cell.token:
      if ch == '.':
        periodCount += 1
    if periodCount == 0:
      var n: int
      try:
        parseutils.parseInt(cell.token, n)
      except ValueError:
        return Cell(kind: Error, error: NumberParseError, readCell: cell)
      Cell(kind: Long, longVal: n.int64, readCell: cell)
    elif periodCount == 1:
      var n: float
      try:
        parseutils.parseFloat(cell.token, n)
      except ValueError:
        return Cell(kind: Error, error: NumberParseError, readCell: cell)
      Cell(kind: Double, doubleVal: n.float64, readCell: cell)
    else:
      Cell(kind: Error, error: NumberParseError, readCell: cell)
  of read.String:
    Cell(kind: String, stringVal: cell.stringValue, readCell: cell)
  of read.Keyword:
    Cell(kind: Keyword, keywordVal: cell.token, readCell: cell)
  else:
    Cell(kind: Error, error: NotImplemented, readCell: cell)

func eval*(cell: read.Cell): Cell =
  var ctx = initContext()
  eval(ctx, cell)
