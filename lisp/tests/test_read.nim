import unittest
from limalisppkg/read import CellKind, Cell, ReadCellKind, ReadErrorKind, ReadCell, `==`

test "lexing":
  check read.lex("1 1") == @[
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
  ]
  check read.lex("(+ 1 1)") == @[
    ReadCell(kind: OpenDelimiter, token: "("),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "+"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("[1 2 3]") == @[
    ReadCell(kind: OpenDelimiter, token: "["),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
    ReadCell(kind: CloseDelimiter, token: "]"),
  ]
  check read.lex("#{1 2 3}") == @[
    ReadCell(kind: SpecialCharacter, token: "#"),
    ReadCell(kind: OpenDelimiter, token: "{"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
    ReadCell(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("{:age 42}") == @[
    ReadCell(kind: OpenDelimiter, token: "{"),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: ":age"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "42"),
    ReadCell(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("^:callable") == @[
    ReadCell(kind: SpecialCharacter, token: "^"),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: ":callable"),
  ]
  check read.lex("'(1, 2, 3)") == @[
    ReadCell(kind: SpecialCharacter, token: "'"),
    ReadCell(kind: OpenDelimiter, token: "("),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
    ReadCell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("`(println ~message)") == @[
    ReadCell(kind: SpecialCharacter, token: "`"),
    ReadCell(kind: OpenDelimiter, token: "("),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "println"),
    ReadCell(kind: SpecialCharacter, token: "~"),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "message"),
    ReadCell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("`(println ~@messages)") == @[
    ReadCell(kind: SpecialCharacter, token: "`"),
    ReadCell(kind: OpenDelimiter, token: "("),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "println"),
    ReadCell(kind: SpecialCharacter, token: "~@"),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "messages"),
    ReadCell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("""; hello world
(+ 1 1)""") == @[
    ReadCell(kind: Comment, token: "; hello world"),
    ReadCell(kind: OpenDelimiter, token: "("),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "+"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("\"hello\"") == @[
    ReadCell(kind: Value, value: Cell(kind: String, stringValue: "hello"), token: "\"hello\""),
  ]
  check read.lex("\"hello \\\"world\\\"\"") == @[
    ReadCell(kind: Value, value: Cell(kind: String, stringValue: "hello \\\"world\\\""), token: "\"hello \\\"world\\\"\""),
  ]
  check read.lex("\"hello") == @[
    ReadCell(kind: Value, value: Cell(kind: String), token: "\"hello", error: NoMatchingUnquote),
  ]
  check read.lex(":hello123") == @[
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: ":hello123"),
  ]
  check read.lex("\\n") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: "\\n"),
  ]
  check read.lex("\\1") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: "\\1"),
  ]
  check read.lex("\\;") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: "\\;"),
  ]
  check read.lex("\\ n") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: "\\", error: NothingValidAfter),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "n"),
  ]
  check read.lex("\\space;hello") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: "\\space"),
    ReadCell(kind: Comment, token: ";hello"),
  ]
  check read.lex("#uuid") == @[
    ReadCell(kind: SpecialCharacter, token: "#"),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "uuid"),
  ]
  check read.lex("hello#") == @[
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "hello#"),
  ]
  block:
    let cells = read.lex("""; hello
(+ 1 1)
:foo""")
    check cells[0].position == (1, 1) # ; hello
    check cells[1].position == (2, 1) # (
    check cells[2].position == (2, 2) # +
    check cells[3].position == (2, 4) # 1
    check cells[4].position == (2, 6) # 1
    check cells[5].position == (2, 7) # 1
    check cells[6].position == (3, 1) # :foo

test "parsing":
  check read.parse(read.lex(":")) == @[
    ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":", error: InvalidKeyword),
  ]
  check read.parse(read.lex(":hello")) == @[
    ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":hello"),
  ]
  check read.parse(read.lex("true false nil")) == @[
    ReadCell(kind: Value, value: Cell(kind: Boolean), token: "true"),
    ReadCell(kind: Value, value: Cell(kind: Boolean), token: "false"),
    ReadCell(kind: Value, value: Cell(kind: Nil), token: "nil"),
  ]
  check read.parse(read.lex("(+ 1 1)")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "("), ReadCell(kind: CloseDelimiter, token: ")")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: "+"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
      ],
    ),
  ]
  check read.parse(read.lex("[1 2 3]")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "["), ReadCell(kind: CloseDelimiter, token: "]")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
      ],
    ),
  ]
  check read.parse(read.lex("#{1 2 3}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "#{"), ReadCell(kind: CloseDelimiter, token: "}")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar 2}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "{"), ReadCell(kind: CloseDelimiter, token: "}")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":foo"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":bar"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "{"), ReadCell(kind: CloseDelimiter, token: "}")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":foo"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: ":bar"),
      ],
      error: MustHaveEvenNumberOfForms,
    ),
  ]
  check read.parse(read.lex("#(+ 1 1)")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "#("), ReadCell(kind: CloseDelimiter, token: ")")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: "+"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
      ],
      error: InvalidDelimiter,
    ),
  ]
  check read.parse(read.lex("(+ 1 (/ 2 3))")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: "("), ReadCell(kind: CloseDelimiter, token: ")")],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: "+"),
        ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
        ReadCell(
          kind: Collection,
          delims: @[ReadCell(kind: OpenDelimiter, token: "("), ReadCell(kind: CloseDelimiter, token: ")")],
          contents: @[
            ReadCell(kind: Value, value: Cell(kind: Symbol), token: "/"),
            ReadCell(kind: Value, value: Cell(kind: Number), token: "2"),
            ReadCell(kind: Value, value: Cell(kind: Number), token: "3"),
          ],
        ),
      ],
    ),
  ]
  check read.parse(read.lex("(1}")) == @[
    ReadCell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
    ReadCell(kind: CloseDelimiter, token: "}", error: NoMatchingOpenDelimiter),
  ]
  check read.parse(read.lex("(1")) == @[
    ReadCell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    ReadCell(kind: Value, value: Cell(kind: Number), token: "1"),
  ]
  check read.parse(read.lex("`(println ~message)")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: "`"),
      ReadCell(
        kind: Collection,
        delims: @[ReadCell(kind: OpenDelimiter, token: "("), ReadCell(kind: CloseDelimiter, token: ")")],
        contents: @[
          ReadCell(kind: Value, value: Cell(kind: Symbol), token: "println"),
          ReadCell(kind: SpecialPair, pair: @[
            ReadCell(kind: SpecialCharacter, token: "~"),
            ReadCell(kind: Value, value: Cell(kind: Symbol), token: "message"),
          ]),
        ]),
    ]),
  ]
  check read.parse(read.lex("`(")) == @[
    ReadCell(kind: SpecialCharacter, token: "`", error: NothingValidAfter),
    ReadCell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
  ]
  check read.parse(read.lex("#mytag hello")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: "#"),
      ReadCell(kind: Value, value: Cell(kind: Symbol), token: "mytag"),
    ]),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: "hello"),
  ]
  check read.parse(read.lex("#_hello")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: "#_"),
      ReadCell(kind: Value, value: Cell(kind: Symbol), token: "hello"),
    ]),
  ]
