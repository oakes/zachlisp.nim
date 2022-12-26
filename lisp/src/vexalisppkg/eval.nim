from ./types import Cell, CellKind, ErrorKind, hash, `==`, `<`, `<=`
from ./print import nil
import tables, unicode
import parazoa
from sequtils import nil
from math import nil

const
  delimToType = {
    "(": List,
    "[": Vector,
    "{": HashMap,
    "#{": HashSet,
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

template toVec(cell: Cell): untyped =
  case cell.kind:
  of List:
    cell.listVal
  of Vector:
    cell.vectorVal
  of HashMap:
    var x = initVec[Cell]()
    for (k, v) in cell.mapVal.pairs:
      x = x.add(Cell(kind: Vector, vectorVal: [k, v].toVec))
    x
  of HashSet:
    var x = initVec[Cell]()
    for k in cell.setVal.items:
      x = x.add(k)
    x
  of Nil:
    initVec[Cell]()
  else:
    return Cell(kind: Error, error: InvalidType, token: cell.token)

template toSet(cell: Cell): untyped =
  case cell.kind:
  of List:
    var x = initSet[Cell]()
    for k in cell.listVal.items:
      x = x.incl(k)
    x
  of Vector:
    var x = initSet[Cell]()
    for k in cell.vectorVal.items:
      x = x.incl(k)
    x
  of HashMap:
    var x = initSet[Cell]()
    for (k, v) in cell.mapVal.pairs:
      x = x.incl(Cell(kind: Vector, vectorVal: [k, v].toVec))
    x
  of HashSet:
    cell.setVal
  of Nil:
    initSet[Cell]()
  else:
    return Cell(kind: Error, error: InvalidType, token: cell.token)

func nilPun(cell: Cell): Cell =
  if cell.kind == Nil:
    Cell(kind: Vector, vectorVal: initVec[Cell]())
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
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  Cell(kind: Vector, vectorVal: cell.toVec)

func set*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  if cell.kind == HashSet:
    cell
  else:
    Cell(kind: HashSet, setVal: cell.toSet)

func nth*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  types.checkKind(args[1], {Long})
  let index = args[1].longVal
  if index < 0:
    return Cell(kind: Error, error: IndexOutOfBounds)
  case cell.kind:
  of List:
    if cell.listVal.len > index:
      cell.listVal.get(index.int)
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of Vector:
    if cell.vectorVal.len > index:
      cell.vectorVal.get(index.int)
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of HashMap:
    # TODO: make this more efficient
    if cell.mapVal.len > index:
      var s: seq[Cell]
      for (k, v) in cell.mapVal.pairs:
        s.add(Cell(kind: Vector, vectorVal: [k, v].toVec))
      s[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  of HashSet:
    # TODO: make this more efficient
    if cell.setVal.len > index:
      var s: seq[Cell]
      for v in cell.setVal.items:
        s.add(v)
      s[index]
    else:
      Cell(kind: Error, error: IndexOutOfBounds)
  else:
    Cell(kind: Error, error: InvalidType, token: cell.token)

func count*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  case cell.kind:
  of List:
    Cell(kind: Long, longVal: cell.listVal.len)
  of Vector:
    Cell(kind: Long, longVal: cell.vectorVal.len)
  of HashMap:
    Cell(kind: Long, longVal: cell.mapVal.len)
  of HashSet:
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
      res.listVal = [arg].toVec & res.listVal
  of Vector:
    res.vectorVal &= contents.toVec
  of HashMap:
    for arg in contents:
      if arg.kind == Vector and arg.vectorVal.len == 2:
        let
          k = arg.vectorVal.get(0)
          v = arg.vectorVal.get(1)
        res.mapVal = res.mapVal.add(k, v)
  of HashSet:
    for arg in contents:
      res.setVal = res.setVal.incl(arg)
  else:
    return Cell(kind: Error, error: InvalidType, token: cell.token)
  res

func conj*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2)
  let cell = args[0].nilPun
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  conj(cell, args[1 ..< args.len])

func cons*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2)
  let lastCell = args[args.len-1].nilPun
  types.checkKind(lastCell, {List, Vector, HashMap, HashSet})
  Cell(kind: List, listVal: args[0 ..< args.len-1].toVec & lastCell.toVec)

func disj*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 2, 2)
  var cell = args[0]
  if args[0].kind == Nil: # nil pun
    cell = Cell(kind: HashSet, setVal: initSet[Cell]())
  types.checkKind(cell, {HashSet})
  cell.setVal = cell.setVal.excl(args[1])
  cell

func list*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: List, listVal: args.toVec)

func vector*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: Vector, vectorVal: args.toVec)

func hashMap*(ctx: types.Context, args: seq[Cell]): Cell =
  if args.len mod 2 != 0:
    return Cell(kind: Error, error: InvalidNumberOfArguments)
  var t = initMap[Cell, Cell]()
  for i in 0 ..< int(args.len / 2):
    t = t.add(args[i*2], args[i*2+1])
  Cell(kind: HashMap, mapVal: t)

func hashSet*(ctx: types.Context, args: seq[Cell]): Cell =
  Cell(kind: HashSet, setVal: args.toSet)

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
  types.checkKind(cell, {List, Vector, HashMap, HashSet})
  case cell.kind:
  of List:
    if key.kind == Long and cell.listVal.len > key.longVal:
      cell.listVal.get(key.longVal.int)
    else:
      notFound
  of Vector:
    if key.kind == Long and cell.vectorVal.len > key.longVal:
      cell.vectorVal.get(key.longVal.int)
    else:
      notFound
  of HashMap:
    if key in cell.mapVal:
      cell.mapVal.get(key)
    else:
      notFound
  of HashSet:
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
  types.checkKind(args, {List, Vector, HashMap, HashSet, Nil})
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
        ret = Cell(kind: Vector, vectorVal: cell.toVec)
    of List:
      ret.listVal &= cell.toVec
    of Vector:
      ret.vectorVal &= cell.toVec
    else:
      return Cell(kind: Error, error: InvalidType, token: cell.token)
  ret

func assoc*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1)
  var cell = args[0]
  if args[0].kind == Nil: # nil pun
    cell = Cell(kind: HashMap, mapVal: initMap[Cell, Cell]())
  types.checkKind(cell, {List, Vector, HashMap})
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
      cell.listVal = cell.listVal.add(key.longVal.int, val)
    of Vector:
      if key.kind != Long:
        return Cell(kind: Error, error: InvalidType, token: key.token)
      elif cell.vectorVal.len <= key.longVal:
        return Cell(kind: Error, error: IndexOutOfBounds, token: key.token)
      cell.vectorVal = cell.vectorVal.add(key.longVal.int, val)
    of HashMap:
      cell.mapVal = cell.mapVal.add(key, val)
    else:
      return Cell(kind: Error, error: InvalidType, token: cell.token)
  cell

func keys*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {HashMap})
  Cell(kind: Vector, vectorVal: sequtils.toSeq(cell.mapVal.keys).toVec)

func values*(ctx: types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  let cell = args[0]
  types.checkKind(cell, {HashMap})
  Cell(kind: Vector, vectorVal: sequtils.toSeq(cell.mapVal.values).toVec)

func initContext*(): types.Context =
  result.printLimit = print.printLimit
  result.vars = {
    "=": Cell(kind: Fn, fnVal: eq, fnStringVal: "="),
    ">": Cell(kind: Fn, fnVal: gt, fnStringVal: ">"),
    ">=": Cell(kind: Fn, fnVal: ge, fnStringVal: ">="),
    "<": Cell(kind: Fn, fnVal: lt, fnStringVal: "<"),
    "<=": Cell(kind: Fn, fnVal: le, fnStringVal: "<="),
    "min": Cell(kind: Fn, fnVal: min, fnStringVal: "min"),
    "max": Cell(kind: Fn, fnVal: max, fnStringVal: "max"),
    "+": Cell(kind: Fn, fnVal: plus, fnStringVal: "+"),
    "-": Cell(kind: Fn, fnVal: minus, fnStringVal: "-"),
    "*": Cell(kind: Fn, fnVal: times, fnStringVal: "*"),
    "/": Cell(kind: Fn, fnVal: divide, fnStringVal: "/"),
    "nan?": Cell(kind: Fn, fnVal: isNaN, fnStringVal: "nan?"),
    "mod": Cell(kind: Fn, fnVal: `mod`, fnStringVal: "mod"),
    "pow": Cell(kind: Fn, fnVal: pow, fnStringVal: "pow"),
    "exp": Cell(kind: Fn, fnVal: exp, fnStringVal: "exp"),
    "floor": Cell(kind: Fn, fnVal: floor, fnStringVal: "floor"),
    "ceil": Cell(kind: Fn, fnVal: ceil, fnStringVal: "ceil"),
    "sqrt": Cell(kind: Fn, fnVal: sqrt, fnStringVal: "sqrt"),
    "abs": Cell(kind: Fn, fnVal: abs, fnStringVal: "abs"),
    "signum": Cell(kind: Fn, fnVal: signum, fnStringVal: "signum"),
    "inc": Cell(kind: Fn, fnVal: inc, fnStringVal: "inc"),
    "dec": Cell(kind: Fn, fnVal: dec, fnStringVal: "dec"),
    "vec": Cell(kind: Fn, fnVal: vec, fnStringVal: "vec"),
    "set": Cell(kind: Fn, fnVal: set, fnStringVal: "set"),
    "nth": Cell(kind: Fn, fnVal: nth, fnStringVal: "nth"),
    "count": Cell(kind: Fn, fnVal: count, fnStringVal: "count"),
    "print": Cell(kind: Fn, fnVal: print.print, fnStringVal: "print"),
    "str": Cell(kind: Fn, fnVal: print.str, fnStringVal: "str"),
    "name": Cell(kind: Fn, fnVal: name, fnStringVal: "name"),
    "conj": Cell(kind: Fn, fnVal: conj, fnStringVal: "conj"),
    "cons": Cell(kind: Fn, fnVal: cons, fnStringVal: "cons"),
    "disj": Cell(kind: Fn, fnVal: disj, fnStringVal: "disj"),
    "list": Cell(kind: Fn, fnVal: list, fnStringVal: "list"),
    "vector": Cell(kind: Fn, fnVal: vector, fnStringVal: "vector"),
    "hash-map": Cell(kind: Fn, fnVal: hashMap, fnStringVal: "hash-map"),
    "hash-set": Cell(kind: Fn, fnVal: hashSet, fnStringVal: "hash-set"),
    "get": Cell(kind: Fn, fnVal: get, fnStringVal: "get"),
    "boolean": Cell(kind: Fn, fnVal: boolean, fnStringVal: "boolean"),
    "long": Cell(kind: Fn, fnVal: long, fnStringVal: "long"),
    "double": Cell(kind: Fn, fnVal: double, fnStringVal: "double"),
    "concat": Cell(kind: Fn, fnVal: concat, fnStringVal: "concat"),
    "assoc": Cell(kind: Fn, fnVal: assoc, fnStringVal: "assoc"),
    "keys": Cell(kind: Fn, fnVal: keys, fnStringVal: "keys"),
    "values": Cell(kind: Fn, fnVal: values, fnStringVal: "values"),
  }.toMap

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
        Cell(kind: List, listVal: initVec[Cell](), token: readCell.token)
    of Vector:
      Cell(kind: Vector, vectorVal: evalCells(ctx, readCell.contents).toVec)
    of HashMap:
      if readCell.contents.len mod 2 != 0:
        return Cell(kind: Error, error: MustHaveEvenNumberOfForms, token: readCell.token)
      let cells = evalCells(ctx, readCell.contents)
      var t = initMap[Cell, Cell]()
      for i in 0 ..< int(cells.len / 2):
        t = t.add(cells[i*2], cells[i*2+1])
      Cell(kind: HashMap, mapVal: t)
    of HashSet:
      var hs = initSet[Cell]()
      for cell in evalCells(ctx, readCell.contents):
        hs = hs.incl(cell)
      Cell(kind: HashSet, setVal: hs)
    else:
      Cell(kind: Error, error: NotImplemented, token: readCell.token)
  of types.Value:
    case readCell.value.kind:
    of types.Symbol:
      if readCell.token.value in ctx.vars:
        var ret = ctx.vars.get(readCell.token.value)
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
