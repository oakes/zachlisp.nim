from ./types import Cell, CellKind, ErrorKind, `==`, `<`, `<=`
from ./print import nil
import tables, sets, unicode
from sequtils import nil
from math import nil

const
  delimToType = {
    "(": List,
    "[": Vector,
    "{": Map,
    "#{": Set,
  }.toTable

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
    return Cell(kind: Error, error: InvalidType, token: cell.token)

template evalCells(ctx: types.Context, readCells: seq[types.ReadCell]): seq[Cell] =
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
    return Cell(kind: Error, error: InvalidType, token: cell.token)

func nilPun(cell: Cell): Cell =
  if cell.kind == Nil:
    Cell(kind: Vector, vectorVal: @[])
  else:
    cell

# public functions

func eq*(ctx: types.Context, args: seq[Cell]): Cell =
  for i in 0 ..< args.len - 1:
    if args[i] != args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func ge*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] < args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func gt*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] <= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func le*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] > args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func lt*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
  for i in 0 ..< args.len - 1:
    if args[i] >= args[i+1]:
      return Cell(kind: Boolean, booleanVal: false)
  Cell(kind: Boolean, booleanVal: true)

func min*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  types.checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg < res:
      res = arg
  res

func max*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  types.checkKind(args, {Long, Double})
  var res = args[0]
  for arg in args[1 ..< args.len]:
    if arg > res:
      res = arg
  res

func plus*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
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

func minus*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  types.checkKind(args, {Long, Double})
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

func times*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkKind(args, {Long, Double})
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

func divide*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  types.checkKind(args, {Long, Double})
  var res: float64 = args[0].toDouble
  for arg in args[1 ..< args.len]:
    res /= arg.toDouble
  Cell(kind: Double, doubleVal: res)

func isNaN*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {Long, Double})
  if cell.kind == Double:
    Cell(kind: Boolean, booleanVal: math.isNaN(cell.doubleVal))
  else:
    Cell(kind: Boolean, booleanVal: false)

func `mod`*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  types.checkKind(args, {Long})
  Cell(kind: Long, longVal: args[0].longVal mod args[1].longVal)

func pow*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  types.checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.pow(args[0].toDouble, args[1].toDouble))

func exp*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.exp(args[0].toDouble))

func floor*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.floor(args[0].toDouble))

func ceil*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.ceil(args[0].toDouble))

func sqrt*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  Cell(kind: Double, doubleVal: math.sqrt(args[0].toDouble))

func abs*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  let arg = args[0]
  if arg.kind == Long:
    Cell(kind: Long, longVal: abs(arg.longVal))
  else:
    Cell(kind: Double, doubleVal: abs(arg.toDouble))

func signum*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long, Double})
  let arg = args[0]
  if arg.kind == Long:
    Cell(kind: Long, longVal: math.sgn(arg.longVal))
  else:
    Cell(kind: Long, longVal: math.sgn(arg.toDouble))

func inc*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long})
  Cell(kind: Long, longVal: args[0].longVal + 1)

func dec*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  types.checkKind(args, {Long})
  Cell(kind: Long, longVal: args[0].longVal - 1)

func vec*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, Map, Set})
  Cell(kind: Vector, vectorVal: toSeq(cell))

func set*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, Map, Set})
  if cell.kind == Set:
    cell
  else:
    Cell(kind: Set, setVal: toSeq(cell).toHashSet)

func nth*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, Map, Set})
  types.checkKind(args[1], {Long})
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
    Cell(kind: Error, error: InvalidType, token: cell.token)

func count*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, Map, Set})
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
    Cell(kind: Error, error: InvalidType, token: cell.token)

func name*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {String, Keyword, Symbol})
  case cell.kind:
  of String:
    cell
  of Keyword:
    Cell(kind: String, stringVal: types.name(cell.keywordVal))
  of Symbol:
    Cell(kind: String, stringVal: cell.symbolVal)
  else:
    Cell(kind: Error, error: InvalidType, token: cell.token)

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
    return Cell(kind: Error, error: InvalidType, token: cell.token)
  res

func conj*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, Map, Set})
  conj(cell, args[1 ..< args.len])

func cons*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2)
  let lastCell = args[args.len-1].nilPun
  types.checkKind(lastCell, {List, Vector, Map, Set})
  Cell(kind: List, listVal: args[0 ..< args.len-1] & toSeq(lastCell))

func disj*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  var cell = args[0]
  if args[0].kind == Nil: # nil pun
    cell = Cell(kind: Set)
  types.checkKind(cell, {Set})
  cell.setVal.excl(args[1])
  cell

func list*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: List, listVal: args)

func vector*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: Vector, vectorVal: args)

func hashMap*(ctx: types.Context, args: seq[Cell]): Cell =
  if args.len mod 2 != 0:
    return Cell(kind: Error, error: InvalidNumberOfArguments)
  var t: Table[Cell, Cell]
  for i in 0 ..< int(args.len / 2):
    t[args[i*2]] = args[i*2+1]
  Cell(kind: Map, mapVal: t)

func hashSet*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: Set, setVal: args.toHashSet)

func get*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 3)
  let
    cell = args[0].nilPun
    key = args[1]
    notFound =
      if args.len == 3:
        args[2]
      else:
        Cell(kind: Nil)
  types.checkKind(cell, {List, Vector, Map, Set})
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
    Cell(kind: Error, error: InvalidType, token: cell.token)

func boolean*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Boolean:
    cell
  of Nil:
    Cell(kind: Boolean, booleanVal: false)
  else:
    Cell(kind: Boolean, booleanVal: true)

func long*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Long:
    cell
  of Double:
    Cell(kind: Long, longVal: cell.doubleVal.int64)
  else:
    Cell(kind: Error, error: InvalidType, token: cell.token)

func double*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  case cell.kind:
  of Double:
    cell
  of Long:
    Cell(kind: Double, doubleVal: cell.longVal.float64)
  else:
    Cell(kind: Error, error: InvalidType, token: cell.token)

func concat*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  types.checkKind(args, {List, Vector, Map, Set, Nil})
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
      return Cell(kind: Error, error: InvalidType, token: cell.token)
  ret

func assoc*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  var cell = args[0]
  if args[0].kind == Nil: # nil pun
    cell = Cell(kind: Map)
  types.checkKind(cell, {List, Vector, Map})
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
        return Cell(kind: Error, error: InvalidType, token: key.token)
      elif cell.listVal.len <= key.longVal:
        return Cell(kind: Error, error: IndexOutOfBounds, token: key.token)
      cell.listVal[key.longVal] = val
    of Vector:
      if key.kind != Long:
        return Cell(kind: Error, error: InvalidType, token: key.token)
      elif cell.vectorVal.len <= key.longVal:
        return Cell(kind: Error, error: IndexOutOfBounds, token: key.token)
      cell.vectorVal[key.longVal] = val
    of Map:
      cell.mapVal[key] = val
    else:
      return Cell(kind: Error, error: InvalidType, token: cell.token)
  cell

func keys*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {Map})
  Cell(kind: Vector, vectorVal: sequtils.toSeq(cell.mapVal.keys))

func values*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {Map})
  Cell(kind: Vector, vectorVal: sequtils.toSeq(cell.mapVal.values))

func initContext*(): types.Context =
  result.printLimit = print.printLimit
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
  result.vars["nan?"] = Cell(kind: Fn, fnVal: isNaN, fnStringVal: "nan?")
  result.vars["mod"] = Cell(kind: Fn, fnVal: `mod`, fnStringVal: "mod")
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
  result.vars["set"] = Cell(kind: Fn, fnVal: set, fnStringVal: "set")
  result.vars["nth"] = Cell(kind: Fn, fnVal: nth, fnStringVal: "nth")
  result.vars["count"] = Cell(kind: Fn, fnVal: count, fnStringVal: "count")
  result.vars["print"] = Cell(kind: Fn, fnVal: print.print, fnStringVal: "print")
  result.vars["str"] = Cell(kind: Fn, fnVal: print.str, fnStringVal: "str")
  result.vars["name"] = Cell(kind: Fn, fnVal: name, fnStringVal: "name")
  result.vars["conj"] = Cell(kind: Fn, fnVal: conj, fnStringVal: "conj")
  result.vars["cons"] = Cell(kind: Fn, fnVal: cons, fnStringVal: "cons")
  result.vars["disj"] = Cell(kind: Fn, fnVal: disj, fnStringVal: "disj")
  result.vars["list"] = Cell(kind: Fn, fnVal: list, fnStringVal: "list")
  result.vars["vector"] = Cell(kind: Fn, fnVal: vector, fnStringVal: "vector")
  result.vars["hash-map"] = Cell(kind: Fn, fnVal: hashMap, fnStringVal: "hash-map")
  result.vars["hash-set"] = Cell(kind: Fn, fnVal: hashSet, fnStringVal: "hash-set")
  result.vars["get"] = Cell(kind: Fn, fnVal: get, fnStringVal: "get")
  result.vars["boolean"] = Cell(kind: Fn, fnVal: boolean, fnStringVal: "boolean")
  result.vars["long"] = Cell(kind: Fn, fnVal: long, fnStringVal: "long")
  result.vars["double"] = Cell(kind: Fn, fnVal: double, fnStringVal: "double")
  result.vars["concat"] = Cell(kind: Fn, fnVal: concat, fnStringVal: "concat")
  result.vars["assoc"] = Cell(kind: Fn, fnVal: assoc, fnStringVal: "assoc")
  result.vars["keys"] = Cell(kind: Fn, fnVal: keys, fnStringVal: "keys")
  result.vars["values"] = Cell(kind: Fn, fnVal: values, fnStringVal: "values")

func invoke*(ctx: types.Context, fn: Cell, args: seq[Cell]): Cell =
  if fn.kind == Fn:
    fn.fnVal(ctx, args)
  else:
    Cell(kind: Error, error: NotAFunction, token: fn.token)

func eval*(ctx: types.Context, readCell: types.ReadCell): Cell =
  if readCell.error != types.None:
    return Cell(kind: Error, error: InvalidToken, token: readCell.token)
  case readCell.kind:
  of types.Collection:
    let delim = readCell.delims[0].token.value
    let typ = delimToType[delim]
    case typ:
    of List:
      let cells = evalCells(ctx, readCell.contents)
      if cells.len > 0:
        var res = invoke(ctx, cells[0], cells[1 ..< cells.len])
        # set the token if it hasn't been set already
        if res.token.value == "":
          res.token = readCell.token
        res
      else:
        Cell(kind: List, listVal: @[], token: readCell.token)
    of Vector:
      Cell(kind: Vector, vectorVal: evalCells(ctx, readCell.contents))
    of Map:
      if readCell.contents.len mod 2 != 0:
        return Cell(kind: Error, error: MustHaveEvenNumberOfForms, token: readCell.token)
      let cells = evalCells(ctx, readCell.contents)
      var t: Table[Cell, Cell]
      for i in 0 ..< int(cells.len / 2):
        t[cells[i*2]] = cells[i*2+1]
      Cell(kind: Map, mapVal: t)
    of Set:
      var hs: HashSet[Cell]
      for cell in evalCells(ctx, readCell.contents):
        hs.incl(cell)
      Cell(kind: Set, setVal: hs)
    else:
      Cell(kind: Error, error: NotImplemented, token: readCell.token)
  of types.Value:
    case readCell.value.kind:
    of types.Symbol:
      if readCell.token.value in ctx.vars:
        var ret = ctx.vars[readCell.token.value]
        ret.token = readCell.token
        ret
      else:
        Cell(kind: Error, error: VarDoesNotExist, token: readCell.token)
    else:
      var ret = readCell.value
      ret.token = readCell.token
      ret
  else:
    Cell(kind: Error, error: NotImplemented, token: readCell.token)

func eval*(readCell: types.ReadCell): Cell =
  var ctx = initContext()
  eval(ctx, readCell)
