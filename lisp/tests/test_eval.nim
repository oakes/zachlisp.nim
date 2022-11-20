import unittest
from limalisppkg/read import CellKind, ErrorKind, Cell, `==`
from limalisppkg/eval import CellKind, ErrorKind, Cell, `==`
from math import nil

test "numbers":
  check eval.eval(read.read("42")[0]) == eval.Cell(kind: Long, longVal: 42)
  check eval.eval(read.read("42.0")[0]) == eval.Cell(kind: Double, doubleVal: 42.0)
  check eval.eval(read.read("-42")[0]) == eval.Cell(kind: Long, longVal: -42)
  check eval.eval(read.read("-42.0")[0]) == eval.Cell(kind: Double, doubleVal: -42.0)

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
  check eval.eval(read.read("(min 1)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(min)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "max":
  check eval.eval(read.read("(max 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(max 1.5 7 1)")[0]) == eval.Cell(kind: Long, longVal: 7)
  check eval.eval(read.read("(max 1 2 2.5)")[0]) == eval.Cell(kind: Double, doubleVal: 2.5)
  check eval.eval(read.read("(max 1)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(max 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(max)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "+":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 1.0)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(+ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(+)")[0]) == eval.Cell(kind: Long, longVal: 0)

test "-":
  check eval.eval(read.read("(- 3 2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 3 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(- 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(-)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "*":
  check eval.eval(read.read("(* 3 2)")[0]) == eval.Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(* 3 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 6.0)
  check eval.eval(read.read("(* 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(*)")[0]) == eval.Cell(kind: Long, longVal: 1)

test "/":
  check eval.eval(read.read("(/ 4 2)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(/ 1 2.0)")[0]) == eval.Cell(kind: Double, doubleVal: 0.5)
  check eval.eval(read.read("(/ 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(/)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "pow":
  check eval.eval(read.read("(pow 2 3)")[0]) == eval.Cell(kind: Double, doubleVal: 8.0)
  check eval.eval(read.read("(pow 2.5 2)")[0]) == eval.Cell(kind: Double, doubleVal: 6.25)
  check eval.eval(read.read("(pow 1 \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(pow)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)
  check eval.eval(read.read("(pow 1)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "exp":
  check eval.eval(read.read("(exp 1)")[0]) == eval.Cell(kind: Double, doubleVal: math.E)
  check eval.eval(read.read("(exp \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(exp)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "floor":
  check eval.eval(read.read("(floor 1.5)")[0]) == eval.Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(floor \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(floor)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "ceil":
  check eval.eval(read.read("(ceil 1.5)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(ceil \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(ceil)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "sqrt":
  check eval.eval(read.read("(sqrt 4)")[0]) == eval.Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(sqrt \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(sqrt)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "abs":
  check eval.eval(read.read("(abs -4)")[0]) == eval.Cell(kind: Long, longVal: 4)
  check eval.eval(read.read("(abs -4.2)")[0]) == eval.Cell(kind: Double, doubleVal: 4.2)
  check eval.eval(read.read("(abs \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(abs)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "signum":
  check eval.eval(read.read("(signum -4)")[0]) == eval.Cell(kind: Long, longVal: -1)
  check eval.eval(read.read("(signum 4.2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(signum \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(signum)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "inc":
  check eval.eval(read.read("(inc 2)")[0]) == eval.Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(inc 1.5)")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

test "dec":
  check eval.eval(read.read("(dec 2)")[0]) == eval.Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(dec 1.5)")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec \"hi\")")[0]) == eval.Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec)")[0]) == eval.Cell(kind: Error, error: InvalidNumberOfArguments)

