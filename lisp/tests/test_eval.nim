import unittest
from limalisppkg/read import nil
from limalisppkg/eval import nil
from limalisppkg/types import CellKind, ErrorKind, Cell, ReadCellKind, ReadErrorKind, ReadCell, `==`
from math import nil
import tables, sets

test "numbers":
  check eval.eval(read.read("42")[0]) == Cell(kind: Long, longVal: 42)
  check eval.eval(read.read("42.0")[0]) == Cell(kind: Double, doubleVal: 42.0)
  check eval.eval(read.read("-42")[0]) == Cell(kind: Long, longVal: -42)
  check eval.eval(read.read("-42.0")[0]) == Cell(kind: Double, doubleVal: -42.0)
  check eval.eval(read.read("(long 1.5)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(double 1)")[0]) == Cell(kind: Double, doubleVal: 1.0)

test "boolean and nil":
  check eval.eval(read.read("true")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("false")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("nil")[0]) == Cell(kind: Nil)
  check eval.eval(read.read("(boolean nil)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(boolean 123)")[0]) == Cell(kind: Boolean, booleanVal: true)

test "=":
  check eval.eval(read.read("(= 1 1 1)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(= 1 2)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(= 1 \"hi\")")[0]) == Cell(kind: Boolean, booleanVal: false)

test ">":
  check eval.eval(read.read("(> 1 1)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 2 1)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(> 1.5 2)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)

test ">=":
  check eval.eval(read.read("(>= 1 1)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 2 1)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 1.5 2)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(>= 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)

test "<":
  check eval.eval(read.read("(< 1 1)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 2)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(< 2 1.5)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)

test "<=":
  check eval.eval(read.read("(<= 1 1)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 1 2)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 2 1.5)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(<= 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)

test "min":
  check eval.eval(read.read("(min 1 2 3)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 1)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 2)")[0]) == Cell(kind: Double, doubleVal: 1.5)
  check eval.eval(read.read("(min 1)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(min)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "max":
  check eval.eval(read.read("(max 1 2 3)")[0]) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(max 1.5 7 1)")[0]) == Cell(kind: Long, longVal: 7)
  check eval.eval(read.read("(max 1 2 2.5)")[0]) == Cell(kind: Double, doubleVal: 2.5)
  check eval.eval(read.read("(max 1)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(max 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(max)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "+":
  check eval.eval(read.read("(+ 1 2 3)")[0]) == Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 1.0)")[0]) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(+ 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(+)")[0]) == Cell(kind: Long, longVal: 0)

test "-":
  check eval.eval(read.read("(- 3 2)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 3 2.0)")[0]) == Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(- 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(-)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "*":
  check eval.eval(read.read("(* 3 2)")[0]) == Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(* 3 2.0)")[0]) == Cell(kind: Double, doubleVal: 6.0)
  check eval.eval(read.read("(* 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(*)")[0]) == Cell(kind: Long, longVal: 1)

test "/":
  check eval.eval(read.read("(/ 4 2)")[0]) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(/ 1 2.0)")[0]) == Cell(kind: Double, doubleVal: 0.5)
  check eval.eval(read.read("(/ 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(/)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "nan?":
  check eval.eval(read.read("(nan? 1)")[0]) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(nan? ##NaN)")[0]) == Cell(kind: Boolean, booleanVal: true)

test "mod":
  check eval.eval(read.read("(mod 3 2)")[0]) == Cell(kind: Long, longVal: 1)

test "pow":
  check eval.eval(read.read("(pow 2 3)")[0]) == Cell(kind: Double, doubleVal: 8.0)
  check eval.eval(read.read("(pow 2.5 2)")[0]) == Cell(kind: Double, doubleVal: 6.25)
  check eval.eval(read.read("(pow 1 \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(pow)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)
  check eval.eval(read.read("(pow 1)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "exp":
  check eval.eval(read.read("(exp 1)")[0]) == Cell(kind: Double, doubleVal: math.E)
  check eval.eval(read.read("(exp \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(exp)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "floor":
  check eval.eval(read.read("(floor 1.5)")[0]) == Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(floor \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(floor)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "ceil":
  check eval.eval(read.read("(ceil 1.5)")[0]) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(ceil \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(ceil)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "sqrt":
  check eval.eval(read.read("(sqrt 4)")[0]) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(sqrt \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(sqrt)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "abs":
  check eval.eval(read.read("(abs -4)")[0]) == Cell(kind: Long, longVal: 4)
  check eval.eval(read.read("(abs -4.2)")[0]) == Cell(kind: Double, doubleVal: 4.2)
  check eval.eval(read.read("(abs \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(abs)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "signum":
  check eval.eval(read.read("(signum -4)")[0]) == Cell(kind: Long, longVal: -1)
  check eval.eval(read.read("(signum 4.2)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(signum \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(signum)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "inc":
  check eval.eval(read.read("(inc 2)")[0]) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(inc 1.5)")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "dec":
  check eval.eval(read.read("(dec 2)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(dec 1.5)")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec \"hi\")")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "vectors":
  check eval.eval(read.read("[1 \"hi\" :wassup]")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ])
  check eval.eval(read.read("[foo-bar]")[0]) == Cell(kind: Error, error: VarDoesNotExist)

test "maps":
  check eval.eval(read.read("{:foo 1 :bar \"hi\"}")[0]) == Cell(kind: Map, mapVal: {
      Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
      Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
    }.toTable
  )
  check eval.eval(read.read("{:foo foo-bar}")[0]) == Cell(kind: Error, error: VarDoesNotExist)

test "sets":
  check eval.eval(read.read("#{:foo 1 :bar 1}")[0]) == Cell(kind: Set, setVal: [
      Cell(kind: Keyword, keywordVal: ":foo"),
      Cell(kind: Long, longVal: 1),
      Cell(kind: Keyword, keywordVal: ":bar"),
    ].toHashSet
  )
  check eval.eval(read.read("#{:foo foo-bar}")[0]) == Cell(kind: Error, error: VarDoesNotExist)

test "vec":
  check eval.eval(read.read("(vec [1 \"hi\" :wassup])")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ])
  check eval.eval(read.read("(vec {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ]),
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ]),
  ])
  check eval.eval(read.read("(vec #{:foo 1 :bar 1})")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ])
  check eval.eval(read.read("(vec nil)")[0]) == Cell(kind: Vector, vectorVal: @[])

test "set":
  check eval.eval(read.read("(set [1 \"hi\" :wassup])")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toHashSet)
  check eval.eval(read.read("(set {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ]),
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ]),
  ].toHashSet)
  check eval.eval(read.read("(set #{:foo 1 :bar 1})")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toHashSet)
  check eval.eval(read.read("(set nil)")[0]) == Cell(kind: Set)

test "nth":
  check eval.eval(read.read("(nth [1 \"hi\" :wassup] 1)")[0]) == Cell(kind: String, stringVal: "hi")
  check eval.eval(read.read("(nth {:foo 1 :bar \"hi\"} 1)")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
  ])
  check eval.eval(read.read("(nth #{:foo 1 :bar 1} 1)")[0]) == Cell(kind: Keyword, keywordVal: ":foo")
  check eval.eval(read.read("(nth [] 0)")[0]) == Cell(kind: Error, error: IndexOutOfBounds)
  check eval.eval(read.read("(nth nil 0)")[0]) == Cell(kind: Error, error: IndexOutOfBounds)

test "count":
  check eval.eval(read.read("(count [1 \"hi\" :wassup])")[0]) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(count {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: Long, longVal: 2)
  check eval.eval(read.read("(count #{:foo 1 :bar 1})")[0]) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(count nil)")[0]) == Cell(kind: Long, longVal: 0)

test "print":
  check eval.eval(read.read("(print 1)")[0]) == Cell(kind: String, stringVal: "1")
  check eval.eval(read.read("(print \"hi\nthere!\")")[0]) == Cell(kind: String, stringVal: "\"hi\\nthere!\"")
  check eval.eval(read.read("(print :wassup)")[0]) == Cell(kind: String, stringVal: ":wassup")
  check eval.eval(read.read("(print [1 \"hi\" :wassup])")[0]) == Cell(kind: String, stringVal: "[1 \"hi\" :wassup]")
  check eval.eval(read.read("(print {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: String, stringVal: "{:bar \"hi\" :foo 1}")
  check eval.eval(read.read("(print #{:foo 1 :bar 1})")[0]) == Cell(kind: String, stringVal: "#{:bar :foo 1}")
  var ctx = eval.initContext()
  ctx.printLimit = 10
  check eval.eval(ctx, read.read("(print \"this string is too long\")")[0]) == Cell(kind: Error, error: PrintLengthLimitExceeded)

test "str":
  check eval.eval(read.read("(str 1)")[0]) == Cell(kind: String, stringVal: "1")
  check eval.eval(read.read("(str \"hi\nthere!\")")[0]) == Cell(kind: String, stringVal: "hi\nthere!")
  check eval.eval(read.read("(str :wassup)")[0]) == Cell(kind: String, stringVal: ":wassup")
  check eval.eval(read.read("(str [1 \"hi\" :wassup])")[0]) == Cell(kind: String, stringVal: "[1 \"hi\" :wassup]")
  check eval.eval(read.read("(str {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: String, stringVal: "{:bar \"hi\" :foo 1}")
  check eval.eval(read.read("(str #{:foo 1 :bar 1})")[0]) == Cell(kind: String, stringVal: "#{:bar :foo 1}")
  check eval.eval(read.read("(str \"hello\" \"world\")")[0]) == Cell(kind: String, stringVal: "helloworld")
  check eval.eval(read.read("(str nil 123)")[0]) == Cell(kind: String, stringVal: "123")
  check eval.eval(read.read("(str {:a nil})")[0]) == Cell(kind: String, stringVal: "{:a nil}")
  var ctx = eval.initContext()
  ctx.printLimit = 10
  check eval.eval(ctx, read.read("(str \"this string is too long\")")[0]) == Cell(kind: Error, error: PrintLengthLimitExceeded)

test "name":
  check eval.eval(read.read("(name \"hi\")")[0]) == Cell(kind: String, stringVal: "hi")
  check eval.eval(read.read("(name :hi)")[0]) == Cell(kind: String, stringVal: "hi")

test "conj":
  check eval.eval(read.read("(conj () 1 2 3)")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 3),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 1),
  ])
  check eval.eval(read.read("(conj [1 \"hi\" :wassup] 2)")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(conj {:foo 1 :bar \"hi\"} [:baz 2])")[0]) == Cell(kind: Map, mapVal: {
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":baz"): Cell(kind: Long, longVal: 2),
  }.toTable)
  check eval.eval(read.read("(conj #{:foo 1 :bar 1} 2)")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
  ].toHashSet)
  check eval.eval(read.read("(conj nil 2)")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(conj :yo 2)")[0]) == Cell(kind: Error, error: InvalidType)

test "cons":
  check eval.eval(read.read("(cons 1 2 3 ())")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 3),
  ])
  check eval.eval(read.read("(cons 2 [1 \"hi\" :wassup])")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ])
  check eval.eval(read.read("(cons 2 {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 2),
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ]),
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ]),
  ])
  check eval.eval(read.read("(cons 2 #{:foo 1 :bar 1})")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 2),
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ])
  check eval.eval(read.read("(cons 2 nil)")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(cons 2 :yo)")[0]) == Cell(kind: Error, error: InvalidType)

test "disj":
  check eval.eval(read.read("(disj #{:foo 1 :bar 1} 1)")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
  ].toHashSet)

test "list":
  check eval.eval(read.read("(list 1 :a \"hi\")")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":a"),
    Cell(kind: String, stringVal: "hi"),
  ])

test "vector":
  check eval.eval(read.read("(vector 1 :a \"hi\")")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":a"),
    Cell(kind: String, stringVal: "hi"),
  ])

test "hash-map":
  check eval.eval(read.read("(hash-map :foo 1 :bar \"hi\")")[0]) == Cell(kind: Map, mapVal: {
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
  }.toTable)

test "hash-set":
  check eval.eval(read.read("(hash-set :foo 1 :bar 1)")[0]) == Cell(kind: Set, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toHashSet)

test "get":
  check eval.eval(read.read("(get [1] 0)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(get [1] 1)")[0]) == Cell(kind: Nil)
  check eval.eval(read.read("(get [1] 1 :hi)")[0]) == Cell(kind: Keyword, keywordVal: ":hi")
  check eval.eval(read.read("(get {:foo 1 :bar \"hi\"} :foo)")[0]) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(get #{:foo 1 :bar 1} :foo)")[0]) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(get nil 2)")[0]) == Cell(kind: Nil)
  check eval.eval(read.read("(get :yo 2)")[0]) == Cell(kind: Error, error: InvalidType)

test "concat":
  check eval.eval(read.read("(concat () [1 2 3])")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 3),
  ])
  check eval.eval(read.read("(concat [1 \"hi\" :wassup] #{2})")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(concat {:foo 1 :bar \"hi\"} [2])")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ]),
    Cell(kind: Vector, vectorVal: @[
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ]),
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(concat #{:foo 1 :bar 1} [2])")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(concat nil [2])")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(concat :yo 2)")[0]) == Cell(kind: Error, error: InvalidType)

test "assoc":
  check eval.eval(read.read("(assoc (list 1 2) 0 3)")[0]) == Cell(kind: List, listVal: @[
    Cell(kind: Long, longVal: 3),
    Cell(kind: Long, longVal: 2),
  ])
  check eval.eval(read.read("(assoc [1 \"hi\"] 1 :wassup)")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ])
  check eval.eval(read.read("(assoc {:foo 1} :bar \"hi\")")[0]) == Cell(kind: Map, mapVal: {
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
  }.toTable)
  check eval.eval(read.read("(assoc nil :bar \"hi\")")[0]) == Cell(kind: Map, mapVal: {
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
  }.toTable)
  check eval.eval(read.read("(assoc #{:foo 1 :bar 1} 0 1)")[0]) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(assoc [] 0 1)")[0]) == Cell(kind: Error, error: IndexOutOfBounds)
  check eval.eval(read.read("(assoc [] 0)")[0]) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "keys":
  check eval.eval(read.read("(keys {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
  ])

test "values":
  check eval.eval(read.read("(values {:foo 1 :bar \"hi\"})")[0]) == Cell(kind: Vector, vectorVal: @[
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Long, longVal: 1),
  ])
