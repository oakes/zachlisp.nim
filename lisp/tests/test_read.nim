import unittest
from limalisppkg/types import CellKind, ErrorKind, Cell, ReadCellKind, ReadErrorKind, ReadCell, Token, `==`
from limalisppkg/read import nil

test "lexing":
  check read.lex("1 1") == @[
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
  ]
  check read.lex("(+ 1 1)") == @[
    ReadCell(kind: OpenDelimiter, token: Token(value: "(")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "+")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: CloseDelimiter, token: Token(value: ")")),
  ]
  check read.lex("[1 2 3]") == @[
    ReadCell(kind: OpenDelimiter, token: Token(value: "[")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
    ReadCell(kind: CloseDelimiter, token: Token(value: "]")),
  ]
  check read.lex("#{1 2 3}") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "#")),
    ReadCell(kind: OpenDelimiter, token: Token(value: "{")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
    ReadCell(kind: CloseDelimiter, token: Token(value: "}")),
  ]
  check read.lex("{:age 42}") == @[
    ReadCell(kind: OpenDelimiter, token: Token(value: "{")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: ":age")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "42")),
    ReadCell(kind: CloseDelimiter, token: Token(value: "}")),
  ]
  check read.lex("^:callable") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "^")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: ":callable")),
  ]
  check read.lex("'(1, 2, 3)") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "'")),
    ReadCell(kind: OpenDelimiter, token: Token(value: "(")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
    ReadCell(kind: CloseDelimiter, token: Token(value: ")")),
  ]
  check read.lex("`(println ~message)") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "`")),
    ReadCell(kind: OpenDelimiter, token: Token(value: "(")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "println")),
    ReadCell(kind: SpecialCharacter, token: Token(value: "~")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "message")),
    ReadCell(kind: CloseDelimiter, token: Token(value: ")")),
  ]
  check read.lex("`(println ~@messages)") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "`")),
    ReadCell(kind: OpenDelimiter, token: Token(value: "(")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "println")),
    ReadCell(kind: SpecialCharacter, token: Token(value: "~@")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "messages")),
    ReadCell(kind: CloseDelimiter, token: Token(value: ")")),
  ]
  check read.lex("""; hello world
(+ 1 1)""") == @[
    ReadCell(kind: Comment, token: Token(value: "; hello world")),
    ReadCell(kind: OpenDelimiter, token: Token(value: "(")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "+")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: CloseDelimiter, token: Token(value: ")")),
  ]
  check read.lex("\"hello\"") == @[
    ReadCell(kind: Value, value: Cell(kind: String, stringVal: "hello"), token: Token(value: "\"hello\"")),
  ]
  check read.lex("\"hello \\\"world\\\"\"") == @[
    ReadCell(kind: Value, value: Cell(kind: String, stringVal: "hello \\\"world\\\""), token: Token(value: "\"hello \\\"world\\\"\"")),
  ]
  check read.lex("\"hello") == @[
    ReadCell(kind: Value, value: Cell(kind: String), token: Token(value: "\"hello"), error: NoMatchingUnquote),
  ]
  check read.lex(":hello123") == @[
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: ":hello123")),
  ]
  check read.lex("\\n") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: "\\n")),
  ]
  check read.lex("\\1") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: "\\1")),
  ]
  check read.lex("\\;") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: "\\;")),
  ]
  check read.lex("\\ n") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: "\\"), error: NothingValidAfter),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "n")),
  ]
  check read.lex("\\space;hello") == @[
    ReadCell(kind: Value, value: Cell(kind: Character), token: Token(value: "\\space")),
    ReadCell(kind: Comment, token: Token(value: ";hello")),
  ]
  check read.lex("#uuid") == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "#")),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "uuid")),
  ]
  check read.lex("hello#") == @[
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "hello#")),
  ]
  block:
    let cells = read.lex("""; hello
(+ 1 1)
:foo""")
    check cells[0].token.position == (1, 1) # ; hello
    check cells[1].token.position == (2, 1) # (
    check cells[2].token.position == (2, 2) # +
    check cells[3].token.position == (2, 4) # 1
    check cells[4].token.position == (2, 6) # 1
    check cells[5].token.position == (2, 7) # 1
    check cells[6].token.position == (3, 1) # :foo

test "parsing":
  check read.parse(read.lex(":")) == @[
    ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":"), error: InvalidKeyword),
  ]
  check read.parse(read.lex(":hello")) == @[
    ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":hello")),
  ]
  check read.parse(read.lex("true false nil")) == @[
    ReadCell(kind: Value, value: Cell(kind: Boolean), token: Token(value: "true")),
    ReadCell(kind: Value, value: Cell(kind: Boolean), token: Token(value: "false")),
    ReadCell(kind: Value, value: Cell(kind: Nil), token: Token(value: "nil")),
  ]
  check read.parse(read.lex("(+ 1 1)")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "(")), ReadCell(kind: CloseDelimiter, token: Token(value: ")"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "+")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
      ],
    ),
  ]
  check read.parse(read.lex("[1 2 3]")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "[")), ReadCell(kind: CloseDelimiter, token: Token(value: "]"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
      ],
    ),
  ]
  check read.parse(read.lex("#{1 2 3}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "#{")), ReadCell(kind: CloseDelimiter, token: Token(value: "}"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar 2}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "{")), ReadCell(kind: CloseDelimiter, token: Token(value: "}"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":foo")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":bar")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
      ],
    ),
  ]
  check read.parse(read.lex("{:foo 1 :bar}")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "{")), ReadCell(kind: CloseDelimiter, token: Token(value: "}"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":foo")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Keyword), token: Token(value: ":bar")),
      ],
      error: MustReadEvenNumberOfForms,
    ),
  ]
  check read.parse(read.lex("#(+ 1 1)")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "#(")), ReadCell(kind: CloseDelimiter, token: Token(value: ")"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "+")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
      ],
      error: InvalidDelimiter,
    ),
  ]
  check read.parse(read.lex("(+ 1 (/ 2 3))")) == @[
    ReadCell(
      kind: Collection,
      delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "(")), ReadCell(kind: CloseDelimiter, token: Token(value: ")"))],
      contents: @[
        ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "+")),
        ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
        ReadCell(
          kind: Collection,
          delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "(")), ReadCell(kind: CloseDelimiter, token: Token(value: ")"))],
          contents: @[
            ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "/")),
            ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "2")),
            ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "3")),
          ],
        ),
      ],
    ),
  ]
  check read.parse(read.lex("(1}")) == @[
    ReadCell(kind: OpenDelimiter, token: Token(value: "("), error: NoMatchingCloseDelimiter),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
    ReadCell(kind: CloseDelimiter, token: Token(value: "}"), error: NoMatchingOpenDelimiter),
  ]
  check read.parse(read.lex("(1")) == @[
    ReadCell(kind: OpenDelimiter, token: Token(value: "("), error: NoMatchingCloseDelimiter),
    ReadCell(kind: Value, value: Cell(kind: Long), token: Token(value: "1")),
  ]
  check read.parse(read.lex("`(println ~message)")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: Token(value: "`")),
      ReadCell(
        kind: Collection,
        delims: @[ReadCell(kind: OpenDelimiter, token: Token(value: "(")), ReadCell(kind: CloseDelimiter, token: Token(value: ")"))],
        contents: @[
          ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "println")),
          ReadCell(kind: SpecialPair, pair: @[
            ReadCell(kind: SpecialCharacter, token: Token(value: "~")),
            ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "message")),
          ]),
        ]),
    ]),
  ]
  check read.parse(read.lex("`(")) == @[
    ReadCell(kind: SpecialCharacter, token: Token(value: "`"), error: NothingValidAfter),
    ReadCell(kind: OpenDelimiter, token: Token(value: "("), error: NoMatchingCloseDelimiter),
  ]
  check read.parse(read.lex("#mytag hello")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: Token(value: "#")),
      ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "mytag")),
    ]),
    ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "hello")),
  ]
  check read.parse(read.lex("#_hello")) == @[
    ReadCell(kind: SpecialPair, pair: @[
      ReadCell(kind: SpecialCharacter, token: Token(value: "#_")),
      ReadCell(kind: Value, value: Cell(kind: Symbol), token: Token(value: "hello")),
    ]),
  ]
