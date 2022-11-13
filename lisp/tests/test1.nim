import unittest
from limalisppkg/read import ElementKind, ErrorKind, Element, `==`

test "lexing":
  check read.lex("1 1") == @[
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "1"),
  ]
  check read.lex("(+ 1 1)") == @[
    Element(kind: OpenDelimiter, token: "("),
    Element(kind: Symbol, token: "+"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "1"),
    Element(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("[1 2 3]") == @[
    Element(kind: OpenDelimiter, token: "["),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: CloseDelimiter, token: "]"),
  ]
  check read.lex("#{1 2 3}") == @[
    Element(kind: OpenDelimiter, token: "#{"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("{:age 42}") == @[
    Element(kind: OpenDelimiter, token: "{"),
    Element(kind: Keyword, token: ":age"),
    Element(kind: Number, token: "42"),
    Element(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("^:callable") == @[
    Element(kind: SpecialCharacter, token: "^"),
    Element(kind: Keyword, token: ":callable"),
  ]
  check read.lex("'(1, 2, 3)") == @[
    Element(kind: SpecialCharacter, token: "'"),
    Element(kind: OpenDelimiter, token: "("),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "2"),
    Element(kind: Number, token: "3"),
    Element(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("`(println ~message)") == @[
    Element(kind: SpecialCharacter, token: "`"),
    Element(kind: OpenDelimiter, token: "("),
    Element(kind: Symbol, token: "println"),
    Element(kind: SpecialCharacter, token: "~"),
    Element(kind: Symbol, token: "message"),
    Element(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("""; hello world
(+ 1 1)""") == @[
    Element(kind: Comment, token: "; hello world"),
    Element(kind: OpenDelimiter, token: "("),
    Element(kind: Symbol, token: "+"),
    Element(kind: Number, token: "1"),
    Element(kind: Number, token: "1"),
    Element(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("\"hello\"") == @[
    Element(kind: String, token: "\"hello\""),
  ]
  check read.lex("\"hello \\\"world\\\"\"") == @[
    Element(kind: String, token: "\"hello \\\"world\\\"\""),
  ]
  check read.lex("\\n") == @[
    Element(kind: Character, token: "\\n"),
  ]
  check read.lex("\\;") == @[
    Element(kind: Character, token: "\\;"),
  ]
  check read.lex("\\ n") == @[
    Element(kind: Character, token: "\\"),
    Element(kind: Symbol, token: "n"),
  ]
  check read.lex("\\space;hello") == @[
    Element(kind: Character, token: "\\space"),
    Element(kind: Comment, token: ";hello"),
  ]

test "parsing":
  check read.parse(read.lex("(+ 1 1)")) == @[
    Element(kind: Collection, elements: @[
        Element(kind: OpenDelimiter, token: "("),
        Element(kind: Symbol, token: "+"),
        Element(kind: Number, token: "1"),
        Element(kind: Number, token: "1"),
        Element(kind: CloseDelimiter, token: ")"),
      ],
    ),
  ]
  check read.parse(read.lex("(+ 1 (/ 2 3))")) == @[
    Element(kind: Collection, elements: @[
        Element(kind: OpenDelimiter, token: "("),
        Element(kind: Symbol, token: "+"),
        Element(kind: Number, token: "1"),
        Element(kind: Collection, elements: @[
            Element(kind: OpenDelimiter, token: "("),
            Element(kind: Symbol, token: "/"),
            Element(kind: Number, token: "2"),
            Element(kind: Number, token: "3"),
            Element(kind: CloseDelimiter, token: ")"),
          ],
        ),
        Element(kind: CloseDelimiter, token: ")"),
      ],
    ),
  ]
  check read.parse(read.lex("(1}")) == @[
    Element(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    Element(kind: Number, token: "1"),
    Element(kind: CloseDelimiter, token: "}", error: NoMatchingOpenDelimiter),
  ]
  check read.parse(read.lex("(1")) == @[
    Element(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    Element(kind: Number, token: "1"),
  ]
  check read.parse(read.lex("`(println ~message)")) == @[
    Element(kind: SpecialPair, elements: @[
      Element(kind: SpecialCharacter, token: "`"),
      Element(kind: Collection, elements: @[
        Element(kind: OpenDelimiter, token: "("),
        Element(kind: Symbol, token: "println"),
        Element(kind: SpecialPair, elements: @[
          Element(kind: SpecialCharacter, token: "~"),
          Element(kind: Symbol, token: "message"),
        ]),
        Element(kind: CloseDelimiter, token: ")"),
      ]),
    ]),
  ]
  check read.parse(read.lex("`(")) == @[
    Element(kind: SpecialCharacter, token: "`", error: NothingValidAfter),
    Element(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
  ]
