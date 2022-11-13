import unittest
from limalisppkg/read import CellKind, ErrorKind, Cell, `==`
from limalisppkg/eval import CellKind, ErrorKind, Cell, `==`

test "evaling":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 6)
