import unittest
from limalisppkg/read import `ElementKind`, `Element`

test "basic reading":
  check read.lex("(+ 1 1)") == @[
    Element(kind: Delimiter, token: "("),
    Element(kind: Symbol, token: "+"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "1"),
    Element(kind: Delimiter, token: ")"),
  ]
  check read.lex("[1 2 3]") == @[
    Element(kind: Delimiter, token: "["),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: Delimiter, token: "]"),
  ]
  check read.lex("#{1 2 3}") == @[
    Element(kind: Delimiter, token: "#{"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: Delimiter, token: "}"),
  ]
  check read.lex("{:age 42}") == @[
    Element(kind: Delimiter, token: "{"),
    Element(kind: Keyword, token: ":age"),
    Element(kind: Number, token: "42"),
    Element(kind: Delimiter, token: "}"),
  ]
  check read.lex("^:callable") == @[
    Element(kind: Special, token: "^"),
    Element(kind: Keyword, token: ":callable"),
  ]
  check read.lex("'(1, 2, 3)") == @[
    Element(kind: Special, token: "'"),
    Element(kind: Delimiter, token: "("),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: Delimiter, token: ")"),
  ]
  check read.lex("`(println ~message)") == @[
    Element(kind: Special, token: "`"),
    Element(kind: Delimiter, token: "("),
    Element(kind: Symbol, token: "println"),
    Element(kind: Special, token: "~"),
    Element(kind: Symbol, token: "message"),
    Element(kind: Delimiter, token: ")"),
  ]
  check read.lex("""; hello world
(+ 1 1)""") == @[
    Element(kind: Comment, token: "; hello world"),
    Element(kind: Delimiter, token: "("),
    Element(kind: Symbol, token: "+"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "1"),
    Element(kind: Delimiter, token: ")"),
  ]
