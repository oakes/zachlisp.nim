import unittest
from limalisppkg/read import CellKind, ErrorKind, Cell, `==`
from limalisppkg/eval import CellKind, ErrorKind, Cell, `==`

test "+":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "-":
  check eval.eval(read.read("(- 3 2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
