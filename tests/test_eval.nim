import unittest
from zachlisppkg/read import nil
from zachlisppkg/eval import nil
import zachlisppkg/types
from math import nil
import parazoa

test "numbers":
  check eval.eval(read.read("42")) == Cell(kind: Long, longVal: 42)
  check eval.eval(read.read("42.0")) == Cell(kind: Double, doubleVal: 42.0)
  check eval.eval(read.read("-42")) == Cell(kind: Long, longVal: -42)
  check eval.eval(read.read("-42.0")) == Cell(kind: Double, doubleVal: -42.0)
  check eval.eval(read.read("(long 1.5)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(double 1)")) == Cell(kind: Double, doubleVal: 1.0)

test "boolean and nil":
  check eval.eval(read.read("true")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("false")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("nil")) == Cell(kind: Nil)
  check eval.eval(read.read("(boolean nil)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(boolean 123)")) == Cell(kind: Boolean, booleanVal: true)

test "=":
  check eval.eval(read.read("(= 1 1 1)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(= 1 2)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(= 1 \"hi\")")) == Cell(kind: Boolean, booleanVal: false)

test ">":
  check eval.eval(read.read("(> 1 1)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 2 1)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(> 1.5 2)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(> 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)

test ">=":
  check eval.eval(read.read("(>= 1 1)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 2 1)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(>= 1.5 2)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(>= 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)

test "<":
  check eval.eval(read.read("(< 1 1)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 2)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(< 2 1.5)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(< 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)

test "<=":
  check eval.eval(read.read("(<= 1 1)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 1 2)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(<= 2 1.5)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(<= 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)

test "min":
  check eval.eval(read.read("(min 1 2 3)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 1)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1.5 7 2)")) == Cell(kind: Double, doubleVal: 1.5)
  check eval.eval(read.read("(min 1)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(min 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(min)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "max":
  check eval.eval(read.read("(max 1 2 3)")) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(max 1.5 7 1)")) == Cell(kind: Long, longVal: 7)
  check eval.eval(read.read("(max 1 2 2.5)")) == Cell(kind: Double, doubleVal: 2.5)
  check eval.eval(read.read("(max 1)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(max 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(max)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "+":
  check eval.eval(read.read("(+ 1 2 3)")) == Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(+ 1 1.0)")) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(+ 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(+)")) == Cell(kind: Long, longVal: 0)

test "-":
  check eval.eval(read.read("(- 3 2)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(- 3 2.0)")) == Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(- 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(-)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "*":
  check eval.eval(read.read("(* 3 2)")) == Cell(kind: Long, longVal: 6)
  check eval.eval(read.read("(* 3 2.0)")) == Cell(kind: Double, doubleVal: 6.0)
  check eval.eval(read.read("(* 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(*)")) == Cell(kind: Long, longVal: 1)

test "/":
  check eval.eval(read.read("(/ 4 2)")) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(/ 1 2.0)")) == Cell(kind: Double, doubleVal: 0.5)
  check eval.eval(read.read("(/ 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(/)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "nan?":
  check eval.eval(read.read("(nan? 1)")) == Cell(kind: Boolean, booleanVal: false)
  check eval.eval(read.read("(nan? ##NaN)")) == Cell(kind: Boolean, booleanVal: true)

test "mod":
  check eval.eval(read.read("(mod 3 2)")) == Cell(kind: Long, longVal: 1)

test "pow":
  check eval.eval(read.read("(pow 2 3)")) == Cell(kind: Double, doubleVal: 8.0)
  check eval.eval(read.read("(pow 2.5 2)")) == Cell(kind: Double, doubleVal: 6.25)
  check eval.eval(read.read("(pow 1 \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(pow)")) == Cell(kind: Error, error: InvalidNumberOfArguments)
  check eval.eval(read.read("(pow 1)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "exp":
  check eval.eval(read.read("(exp 1)")) == Cell(kind: Double, doubleVal: math.E)
  check eval.eval(read.read("(exp \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(exp)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "floor":
  check eval.eval(read.read("(floor 1.5)")) == Cell(kind: Double, doubleVal: 1.0)
  check eval.eval(read.read("(floor \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(floor)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "ceil":
  check eval.eval(read.read("(ceil 1.5)")) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(ceil \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(ceil)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "sqrt":
  check eval.eval(read.read("(sqrt 4)")) == Cell(kind: Double, doubleVal: 2.0)
  check eval.eval(read.read("(sqrt \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(sqrt)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "abs":
  check eval.eval(read.read("(abs -4)")) == Cell(kind: Long, longVal: 4)
  check eval.eval(read.read("(abs -4.2)")) == Cell(kind: Double, doubleVal: 4.2)
  check eval.eval(read.read("(abs \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(abs)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "signum":
  check eval.eval(read.read("(signum -4)")) == Cell(kind: Long, longVal: -1)
  check eval.eval(read.read("(signum 4.2)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(signum \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(signum)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "inc":
  check eval.eval(read.read("(inc 2)")) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(inc 1.5)")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(inc)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "dec":
  check eval.eval(read.read("(dec 2)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(dec 1.5)")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec \"hi\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(dec)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "vectors":
  check eval.eval(read.read("[1 \"hi\" :wassup]")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toVec)
  check eval.eval(read.read("[foo-bar]")) == Cell(kind: Error, error: VarDoesNotExist)

test "maps":
  check eval.eval(read.read("{:foo 1 :bar \"hi\"}")) == Cell(kind: HashMap, mapVal: {
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
  }.toMap)
  check eval.eval(read.read("{:foo foo-bar}")) == Cell(kind: Error, error: VarDoesNotExist)

test "sets":
  check eval.eval(read.read("#{:foo 1 :bar 1}")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"),
  ].toSet)
  check eval.eval(read.read("#{:foo foo-bar}")) == Cell(kind: Error, error: VarDoesNotExist)

test "vec":
  check eval.eval(read.read("(vec [1 \"hi\" :wassup])")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toVec)
  check eval.eval(read.read("(vec {:foo 1 :bar \"hi\"})")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ].toVec),
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ].toVec),
  ].toVec)
  check eval.eval(read.read("(vec #{:foo 1 :bar 1})")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toVec)
  check eval.eval(read.read("(vec nil)")) == Cell(kind: Vector, vectorVal: initVec[Cell]())

test "set":
  check eval.eval(read.read("(set [1 \"hi\" :wassup])")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toSet)
  check eval.eval(read.read("(set {:foo 1 :bar \"hi\"})")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ].toVec),
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ].toVec),
  ].toSet)
  check eval.eval(read.read("(set #{:foo 1 :bar 1})")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toSet)
  check eval.eval(read.read("(set nil)")) == Cell(kind: HashSet)

test "nth":
  check eval.eval(read.read("(nth [1 \"hi\" :wassup] 1)")) == Cell(kind: String, stringVal: "hi")
  check eval.eval(read.read("(nth {:foo 1 :bar \"hi\"} 1)")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
  ].toVec)
  check eval.eval(read.read("(nth #{:foo 1 :bar 1} 1)")) == Cell(kind: Keyword, keywordVal: ":foo")
  check eval.eval(read.read("(nth [] 0)")) == Cell(kind: Error, error: IndexOutOfBounds)
  check eval.eval(read.read("(nth nil 0)")) == Cell(kind: Error, error: IndexOutOfBounds)

test "count":
  check eval.eval(read.read("(count [1 \"hi\" :wassup])")) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(count {:foo 1 :bar \"hi\"})")) == Cell(kind: Long, longVal: 2)
  check eval.eval(read.read("(count #{:foo 1 :bar 1})")) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(count nil)")) == Cell(kind: Long, longVal: 0)

test "print":
  check eval.eval(read.read("(print 1)")) == Cell(kind: String, stringVal: "1")
  check eval.eval(read.read("(print \"hi\nthere!\")")) == Cell(kind: String, stringVal: "\"hi\\nthere!\"")
  check eval.eval(read.read("(print :wassup)")) == Cell(kind: String, stringVal: ":wassup")
  check eval.eval(read.read("(print [1 \"hi\" :wassup])")) == Cell(kind: String, stringVal: "[1 \"hi\" :wassup]")
  check eval.eval(read.read("(print {:foo 1 :bar \"hi\"})")) == Cell(kind: String, stringVal: "{:bar \"hi\" :foo 1}")
  check eval.eval(read.read("(print #{:foo 1 :bar 1})")) == Cell(kind: String, stringVal: "#{:bar :foo 1}")
  var ctx = eval.initContext()
  ctx.printLimit = 10
  check eval.eval(ctx, read.read("(print \"this string is too long\")")) == Cell(kind: Error, error: PrintLengthLimitExceeded)

test "str":
  check eval.eval(read.read("(str 1)")) == Cell(kind: String, stringVal: "1")
  check eval.eval(read.read("(str \"hi\nthere!\")")) == Cell(kind: String, stringVal: "hi\nthere!")
  check eval.eval(read.read("(str :wassup)")) == Cell(kind: String, stringVal: ":wassup")
  check eval.eval(read.read("(str [1 \"hi\" :wassup])")) == Cell(kind: String, stringVal: "[1 \"hi\" :wassup]")
  check eval.eval(read.read("(str {:foo 1 :bar \"hi\"})")) == Cell(kind: String, stringVal: "{:bar \"hi\" :foo 1}")
  check eval.eval(read.read("(str #{:foo 1 :bar 1})")) == Cell(kind: String, stringVal: "#{:bar :foo 1}")
  check eval.eval(read.read("(str \"hello\" \"world\")")) == Cell(kind: String, stringVal: "helloworld")
  check eval.eval(read.read("(str nil 123)")) == Cell(kind: String, stringVal: "123")
  check eval.eval(read.read("(str {:a nil})")) == Cell(kind: String, stringVal: "{:a nil}")
  var ctx = eval.initContext()
  ctx.printLimit = 10
  check eval.eval(ctx, read.read("(str \"this string is too long\")")) == Cell(kind: Error, error: PrintLengthLimitExceeded)

test "name":
  check eval.eval(read.read("(name \"hi\")")) == Cell(kind: String, stringVal: "hi")
  check eval.eval(read.read("(name :hi)")) == Cell(kind: String, stringVal: "hi")

test "conj":
  check eval.eval(read.read("(conj () 1 2 3)")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 3),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 1),
  ].toVec)
  check eval.eval(read.read("(conj [1 \"hi\" :wassup] 2)")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(conj {:foo 1 :bar \"hi\"} [:baz 2])")) == Cell(kind: HashMap, mapVal: {
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":baz"): Cell(kind: Long, longVal: 2),
  }.toMap)
  check eval.eval(read.read("(conj #{:foo 1 :bar 1} 2)")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
  ].toSet)
  check eval.eval(read.read("(conj nil 2)")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(conj :yo 2)")) == Cell(kind: Error, error: InvalidType)

test "cons":
  check eval.eval(read.read("(cons 1 2 3 ())")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 3),
  ].toVec)
  check eval.eval(read.read("(cons 2 [1 \"hi\" :wassup])")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toVec)
  check eval.eval(read.read("(cons 2 {:foo 1 :bar \"hi\"})")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 2),
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ].toVec),
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ].toVec),
  ].toVec)
  check eval.eval(read.read("(cons 2 #{:foo 1 :bar 1})")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 2),
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toVec)
  check eval.eval(read.read("(cons 2 nil)")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(cons 2 :yo)")) == Cell(kind: Error, error: InvalidType)

test "disj":
  check eval.eval(read.read("(disj #{:foo 1 :bar 1} 1)")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
  ].toSet)

test "list":
  check eval.eval(read.read("(list 1 :a \"hi\")")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":a"),
    Cell(kind: String, stringVal: "hi"),
  ].toVec)

test "vector":
  check eval.eval(read.read("(vector 1 :a \"hi\")")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":a"),
    Cell(kind: String, stringVal: "hi"),
  ].toVec)

test "hash-map":
  check eval.eval(read.read("(hash-map :foo 1 :bar \"hi\")")) == Cell(kind: HashMap, mapVal: {
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
  }.toMap)

test "hash-set":
  check eval.eval(read.read("(hash-set :foo 1 :bar 1)")) == Cell(kind: HashSet, setVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
  ].toSet)

test "get":
  check eval.eval(read.read("(get [1] 0)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(get [1] 1)")) == Cell(kind: Nil)
  check eval.eval(read.read("(get [1] 1 :hi)")) == Cell(kind: Keyword, keywordVal: ":hi")
  check eval.eval(read.read("(get {:foo 1 :bar \"hi\"} :foo)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(get #{:foo 1 :bar 1} :foo)")) == Cell(kind: Boolean, booleanVal: true)
  check eval.eval(read.read("(get nil 2)")) == Cell(kind: Nil)
  check eval.eval(read.read("(get :yo 2)")) == Cell(kind: Error, error: InvalidType)

test "concat":
  check eval.eval(read.read("(concat () [1 2 3])")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
    Cell(kind: Long, longVal: 3),
  ].toVec)
  check eval.eval(read.read("(concat [1 \"hi\" :wassup] #{2})")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":wassup"),
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(concat {:foo 1 :bar \"hi\"} [2])")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":bar"), Cell(kind: String, stringVal: "hi"),
    ].toVec),
    Cell(kind: Vector, vectorVal: [
      Cell(kind: Keyword, keywordVal: ":foo"), Cell(kind: Long, longVal: 1),
    ].toVec),
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(concat #{:foo 1 :bar 1} [2])")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(concat nil [2])")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(concat :yo 2)")) == Cell(kind: Error, error: InvalidType)

test "assoc":
  check eval.eval(read.read("(assoc (list 1 2) 0 3)")) == Cell(kind: List, listVal: [
    Cell(kind: Long, longVal: 3),
    Cell(kind: Long, longVal: 2),
  ].toVec)
  check eval.eval(read.read("(assoc [1 \"hi\"] 1 :wassup)")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Long, longVal: 1),
    Cell(kind: Keyword, keywordVal: ":wassup"),
  ].toVec)
  check eval.eval(read.read("(assoc {:foo 1} :bar \"hi\")")) == Cell(kind: HashMap, mapVal: {
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
    Cell(kind: Keyword, keywordVal: ":foo"): Cell(kind: Long, longVal: 1),
  }.toMap)
  check eval.eval(read.read("(assoc nil :bar \"hi\")")) == Cell(kind: HashMap, mapVal: {
    Cell(kind: Keyword, keywordVal: ":bar"): Cell(kind: String, stringVal: "hi"),
  }.toMap)
  check eval.eval(read.read("(assoc #{:foo 1 :bar 1} 0 1)")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(assoc [] 0 1)")) == Cell(kind: Error, error: IndexOutOfBounds)
  check eval.eval(read.read("(assoc [] 0)")) == Cell(kind: Error, error: InvalidNumberOfArguments)

test "keys":
  check eval.eval(read.read("(keys {:foo 1 :bar \"hi\"})")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: Keyword, keywordVal: ":bar"),
    Cell(kind: Keyword, keywordVal: ":foo"),
  ].toVec)

test "values":
  check eval.eval(read.read("(values {:foo 1 :bar \"hi\"})")) == Cell(kind: Vector, vectorVal: [
    Cell(kind: String, stringVal: "hi"),
    Cell(kind: Long, longVal: 1),
  ].toVec)

test "def":
  check eval.eval(read.read("(def a 1) (def b (* a 2)) (+ a b)")) == Cell(kind: Long, longVal: 3)
  check eval.eval(read.read("(def def 2) (def x 2) (+ def x)")) == Cell(kind: Long, longVal: 4)

test "quote":
  check eval.eval(read.read("(quote (+ 1 1))")) == Cell(kind: List, listVal: [
    Cell(kind: Symbol, symbolVal: "+"),
    Cell(kind: Long, longVal: 1),
    Cell(kind: Long, longVal: 1),
  ].toVec)

test "fn":
  check eval.eval(read.read("(def f (fn [] \"foo\")) (f)")) == Cell(kind: String, stringVal: "foo")
  check eval.eval(read.read("(def f (fn [] \"foo\")) (f 1)")) == Cell(kind: Error, error: InvalidNumberOfArguments)
  check eval.eval(read.read("(def f (fn [:hi] \"foo\"))")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(def f (fn [x] :this-is-ignored (* x x))) (f 2)")) == Cell(kind: Long, longVal: 4)
  check eval.eval(read.read("(def f (fn [] (def foo :hi))) (f) foo")) == Cell(kind: Keyword, keywordVal: ":hi")

test "defn":
  check eval.eval(read.read("(defn f [] \"foo\") (f)")) == Cell(kind: String, stringVal: "foo")
  check eval.eval(read.read("(defn f [] \"foo\") (f 1)")) == Cell(kind: Error, error: InvalidNumberOfArguments)
  check eval.eval(read.read("(defn f [:hi] \"foo\")")) == Cell(kind: Error, error: InvalidType)
  check eval.eval(read.read("(defn f [x] :this-is-ignored (* x x)) (f 2)")) == Cell(kind: Long, longVal: 4)
  check eval.eval(read.read("(defn f [] (def foo :hi)) (f) foo")) == Cell(kind: Keyword, keywordVal: ":hi")

test "macro":
  check eval.eval(read.read("(def m (macro [] (list + 1 1))) (m)")) == Cell(kind: Long, longVal: 2)

test "defmacro":
  check eval.eval(read.read("(defmacro m [] (list + 1 1)) (m)")) == Cell(kind: Long, longVal: 2)

test "let":
  check eval.eval(read.read("(let [a])")) == Cell(kind: Error, error: LetMustHaveEvenNumberOfForms)
  check eval.eval(read.read("(let [a 1] a)")) == Cell(kind: Long, longVal: 1)
  check eval.eval(read.read("(let [a 1 b (+ 1 1)] (let [c 3] (+ a b c)))")) == Cell(kind: Long, longVal: 6)
