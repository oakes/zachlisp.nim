import unittest
from limalisppkg/read import CellKind, ErrorKind, Cell, `==`
from limalisppkg/eval import CellKind, ErrorKind, Cell, `==`
from math import nil

test "numbers":
  check eval.eval(read.read("42")[0]) == eval.Cell(kind: Long, longVal: 42)
  check eval.eval(read.read("42.0")[0]) == eval.Cell(kind: Double, doubleVal: 42.0)

test "=":
  check eval.eval(read.read("(= 1 1 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(= 1 2)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(= 1 \"hi\")")[0]) == eval.Cell(kind: Boolean, booleanVal: false)

test ">":
  check eval.eval(read.read("(> 1 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 2 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(> 1.5 2)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test ">=":
  check eval.eval(read.read("(>= 1 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 2 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 1.5 2)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(>= 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "<":
  check eval.eval(read.read("(< 1 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 2)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(< 2 1.5)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "<=":
  check eval.eval(read.read("(<= 1 1)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 1 2)")[0]) == eval.Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 2 1.5)")[0]) == eval.Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(<= 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "min":
  check eval.eval(read.read("(min 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 1)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 2)")[0]) == eval.Cell(kind: Double, doubleVal: 1.5)
  check eval.eval(read.read("(min 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "max":
  check eval.eval(read.read("(max 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(max 1.5 7 1)")[0]) == eval.Cell(kind: Long, longVal: 7)
  check eval.eval(read.read("(max 1 2 2.5)")[0]) == eval.Cell(kind: Double, doubleVal: 2.5)
  check eval.eval(read.read("(max 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "+":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 1.0)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(+ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "-":
  check eval.eval(read.read("(- 3 2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 3 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(- 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "*":
  check eval.eval(read.read("(* 3 2)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(* 3 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 6.0)
  check eval.eval(read.read("(* 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "/":
  check eval.eval(read.read("(/ 4 2)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(/ 1 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 0.5)
  check eval.eval(read.read("(/ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "pow":
  check eval.eval(read.read("(pow 2 3)")[0]) == eval.Cell(kind: Double, doubleVal: 8.0)
  check eval.eval(read.read("(pow 2.5 2)")[0]) == eval.Cell(kind: Double, doubleVal: 6.25)
  check eval.eval(read.read("(pow 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

test "exp":
  check eval.eval(read.read("(exp 1)")[0]) == eval.Cell(kind: Double, doubleVal: math.E)
  check eval.eval(read.read("(exp \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)

