import unittest
from limalisppkg/read import CellValueKind, CellValue, CellKind, ErrorKind, Cell, `==`

test "lexing":
  check read.lex("1 1") == @[
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
  ]
  check read.lex("(+ 1 1)") == @[
    Cell(kind: OpenDelimiter, token: "("),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "+"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("[1 2 3]") == @[
    Cell(kind: OpenDelimiter, token: "["),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
    Cell(kind: CloseDelimiter, token: "]"),
  ]
  check read.lex("#{1 2 3}") == @[
    Cell(kind: SpecialCharacter, token: "#"),
    Cell(kind: OpenDelimiter, token: "{"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
    Cell(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("{:age 42}") == @[
    Cell(kind: OpenDelimiter, token: "{"),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: ":age"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "42"),
    Cell(kind: CloseDelimiter, token: "}"),
  ]
  check read.lex("^:callable") == @[
    Cell(kind: SpecialCharacter, token: "^"),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: ":callable"),
  ]
  check read.lex("'(1, 2, 3)") == @[
    Cell(kind: SpecialCharacter, token: "'"),
    Cell(kind: OpenDelimiter, token: "("),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
    Cell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("`(println ~message)") == @[
    Cell(kind: SpecialCharacter, token: "`"),
    Cell(kind: OpenDelimiter, token: "("),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "println"),
    Cell(kind: SpecialCharacter, token: "~"),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "message"),
    Cell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("`(println ~@messages)") == @[
    Cell(kind: SpecialCharacter, token: "`"),
    Cell(kind: OpenDelimiter, token: "("),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "println"),
    Cell(kind: SpecialCharacter, token: "~@"),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "messages"),
    Cell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("""; hello world
(+ 1 1)""") == @[
    Cell(kind: Comment, token: "; hello world"),
    Cell(kind: OpenDelimiter, token: "("),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "+"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: CloseDelimiter, token: ")"),
  ]
  check read.lex("\"hello\"") == @[
    Cell(kind: Value, value: CellValue(kind: String, stringValue: "hello"), token: "\"hello\""),
  ]
  check read.lex("\"hello \\\"world\\\"\"") == @[
    Cell(kind: Value, value: CellValue(kind: String, stringValue: "hello \\\"world\\\""), token: "\"hello \\\"world\\\"\""),
  ]
  check read.lex("\"hello") == @[
    Cell(kind: Value, value: CellValue(kind: String), token: "\"hello", error: NoMatchingUnquote),
  ]
  check read.lex(":hello123") == @[
    Cell(kind: Value, value: CellValue(kind: Symbol), token: ":hello123"),
  ]
  check read.lex("\\n") == @[
    Cell(kind: Value, value: CellValue(kind: Character), token: "\\n"),
  ]
  check read.lex("\\1") == @[
    Cell(kind: Value, value: CellValue(kind: Character), token: "\\1"),
  ]
  check read.lex("\\;") == @[
    Cell(kind: Value, value: CellValue(kind: Character), token: "\\;"),
  ]
  check read.lex("\\ n") == @[
    Cell(kind: Value, value: CellValue(kind: Character), token: "\\", error: NothingValidAfter),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "n"),
  ]
  check read.lex("\\space;hello") == @[
    Cell(kind: Value, value: CellValue(kind: Character), token: "\\space"),
    Cell(kind: Comment, token: ";hello"),
  ]
  check read.lex("#uuid") == @[
    Cell(kind: SpecialCharacter, token: "#"),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "uuid"),
  ]
  check read.lex("hello#") == @[
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "hello#"),
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
    Cell(kind: Value, value: CellValue(kind: Keyword), token: ":", error: InvalidKeyword),
  ]
  check read.parse(read.lex(":hello")) == @[
    Cell(kind: Value, value: CellValue(kind: Keyword), token: ":hello"),
  ]
  check read.parse(read.lex("true false nil")) == @[
    Cell(kind: Value, value: CellValue(kind: Boolean), token: "true"),
    Cell(kind: Value, value: CellValue(kind: Boolean), token: "false"),
    Cell(kind: Value, value: CellValue(kind: Nil), token: "nil"),
  ]
  check read.parse(read.lex("(+ 1 1)")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "("), Cell(kind: CloseDelimiter, token: ")")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Symbol), token: "+"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
      ],
    ),
  ]
  check read.parse(read.lex("[1 2 3]")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "["), Cell(kind: CloseDelimiter, token: "]")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
      ],
    ),
  ]
  check read.parse(read.lex("#{1 2 3}")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "#{"), Cell(kind: CloseDelimiter, token: "}")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar 2}")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "{"), Cell(kind: CloseDelimiter, token: "}")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Keyword), token: ":foo"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Keyword), token: ":bar"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar}")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "{"), Cell(kind: CloseDelimiter, token: "}")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Keyword), token: ":foo"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Keyword), token: ":bar"),
      ],
      error: MustHaveEvenNumberOfForms,
    ),
  ]
  check read.parse(read.lex("#(+ 1 1)")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "#("), Cell(kind: CloseDelimiter, token: ")")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Symbol), token: "+"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
      ],
      error: InvalidDelimiter,
    ),
  ]
  check read.parse(read.lex("(+ 1 (/ 2 3))")) == @[
    Cell(
      kind: Collection,
      delims: @[Cell(kind: OpenDelimiter, token: "("), Cell(kind: CloseDelimiter, token: ")")],
      contents: @[
        Cell(kind: Value, value: CellValue(kind: Symbol), token: "+"),
        Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
        Cell(
          kind: Collection,
          delims: @[Cell(kind: OpenDelimiter, token: "("), Cell(kind: CloseDelimiter, token: ")")],
          contents: @[
            Cell(kind: Value, value: CellValue(kind: Symbol), token: "/"),
            Cell(kind: Value, value: CellValue(kind: Number), token: "2"),
            Cell(kind: Value, value: CellValue(kind: Number), token: "3"),
          ],
        ),
      ],
    ),
  ]
  check read.parse(read.lex("(1}")) == @[
    Cell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
    Cell(kind: CloseDelimiter, token: "}", error: NoMatchingOpenDelimiter),
  ]
  check read.parse(read.lex("(1")) == @[
    Cell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
    Cell(kind: Value, value: CellValue(kind: Number), token: "1"),
  ]
  check read.parse(read.lex("`(println ~message)")) == @[
    Cell(kind: SpecialPair, pair: @[
      Cell(kind: SpecialCharacter, token: "`"),
      Cell(
        kind: Collection,
        delims: @[Cell(kind: OpenDelimiter, token: "("), Cell(kind: CloseDelimiter, token: ")")],
        contents: @[
          Cell(kind: Value, value: CellValue(kind: Symbol), token: "println"),
          Cell(kind: SpecialPair, pair: @[
            Cell(kind: SpecialCharacter, token: "~"),
            Cell(kind: Value, value: CellValue(kind: Symbol), token: "message"),
          ]),
        ]),
    ]),
  ]
  check read.parse(read.lex("`(")) == @[
    Cell(kind: SpecialCharacter, token: "`", error: NothingValidAfter),
    Cell(kind: OpenDelimiter, token: "(", error: NoMatchingCloseDelimiter),
  ]
  check read.parse(read.lex("#mytag hello")) == @[
    Cell(kind: SpecialPair, pair: @[
      Cell(kind: SpecialCharacter, token: "#"),
      Cell(kind: Value, value: CellValue(kind: Symbol), token: "mytag"),
    ]),
    Cell(kind: Value, value: CellValue(kind: Symbol), token: "hello"),
  ]
  check read.parse(read.lex("#_hello")) == @[
    Cell(kind: SpecialPair, pair: @[
      Cell(kind: SpecialCharacter, token: "#_"),
      Cell(kind: Value, value: CellValue(kind: Symbol), token: "hello"),
    ]),
  ]
