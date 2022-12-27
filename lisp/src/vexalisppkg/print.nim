import ./types
import unicode
import parazoa

const printLimit* = 10000

func print(cell: Cell, shouldEscape: bool, limit: var int): Cell

template printCell(cell: Cell, limit: var int): untyped =
  let printedCell = print(cell, true, limit)
  if printedCell.kind == Error:
    return printedCell
  printedCell.stringVal

template printCells(cells: Vec[Cell], limit: var int): untyped =
  var baseCell = Cell(kind: String, stringVal: "")
  var i = 0
  for cell in cells:
    baseCell.stringVal &= printCell(cell, limit)
    if i + 1 < cells.len:
      baseCell.stringVal &= " "
    i += 1
  baseCell.stringVal

template printCells(cells: Map[Cell, Cell], limit: var int): untyped =
  var baseCell = Cell(kind: String, stringVal: "")
  var i = 0
  for (k, v) in cells.pairs:
    baseCell.stringVal &= printCell(k, limit) & " " & printCell(v, limit)
    if i + 1 < cells.len:
      baseCell.stringVal &= " "
    i += 1
  baseCell.stringVal

template printCells(cells: Set[Cell], limit: var int): untyped =
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
  of Character:
    ($cell.characterVal).toString(limit)
  of Symbol:
    cell.symbolVal.toString(limit)
  of String:
    if shouldEscape:
      var s = ""
      for ch in cell.stringVal:
        addEscapedChar(s, ch)
      s = "\"" & s & "\""
      s.toString(limit)
    else:
      cell.stringVal.toString(limit)
  of Keyword:
    cell.keywordVal.toString(limit)
  of List:
    limit -= 2
    Cell(kind: String, stringVal: "(" & printCells(cell.listVal, limit) & ")")
  of Vector:
    limit -= 2
    Cell(kind: String, stringVal: "[" & printCells(cell.vectorVal, limit) & "]")
  of HashMap:
    limit -= 2
    Cell(kind: String, stringVal: "{" & printCells(cell.mapVal, limit) & "}")
  of HashSet:
    limit -= 3
    Cell(kind: String, stringVal: "#{" & printCells(cell.setVal, limit) & "}")
  of Fn:
    cell.fnStringVal.toString(limit)
  of Macro:
    cell.macroStringVal.toString(limit)
  of Quote:
    print(cell.quoteVal[], shouldEscape, limit)

func str*(ctx: var types.Context, args: seq[Cell]): Cell =
  var
    limit = ctx.printLimit
    retCell = Cell(kind: String, stringVal: "")
  for cell in args:
    let printedCell = print(cell, false, limit)
    if printedCell.kind == Error:
      return printedCell
    retCell.stringVal &= printedCell.stringVal
  retCell

func print*(ctx: var types.Context, args: seq[Cell]): Cell =
  types.checkCount(args.len, 1, 1)
  var limit = ctx.printLimit
  print(args[0], true, limit)

func print*(ctx: var types.Context, cell: types.Cell): Cell =
  print(ctx, @[cell])
