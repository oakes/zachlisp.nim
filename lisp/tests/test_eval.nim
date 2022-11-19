import unittest
from limalisppkg/read import CellKind, ErrorKind, Cell, `==`
from limalisppkg/eval import CellKind, ErrorKind, Cell, `==`

test "numbers":
  check eval.eval(read.read("42")[0]) == eval.Cell(kind: Long, longVal: 42)
  check eval.eval(read.read("42.0")[0]) == eval.Cell(kind: Double, doubleVal: 42.0)

test "+":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 1.0)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(+ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "-":
  check eval.eval(read.read("(- 3 2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 3 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(- 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
