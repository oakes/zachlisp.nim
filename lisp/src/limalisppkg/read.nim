import unicode

type
  ElementKind* = enum
    Whitespace,
    Delimiter,
    Symbol,
    Number,
    Keyword,
    Dispatch,
    Special,
    Comment,
    String,
    Character,
  Element* = object
    kind*: ElementKind
    token*: string

const
  delims = {'(', ')', '[', ']', '{', '}'}
  digits = {'0'..'9'}
  whitespace = {' ', '\t', '\r', '\n', ','}
  hash = '#'
  colon = ':'
  specialCharacters = {'^', '\'', '`', '~'}
  newline = '\n'
  semicolon = ';'
  doublequote = '"'
  backslash = '\\'
  invalidAfterCharacter = {' ', '\t', '\r', '\n'}

func lex*(code: string, discardTypes: set[ElementKind] = {Whitespace}): seq[Element] =
  var
    temp = Element(kind: Whitespace, token: "")
    escaping = false

  proc flush(res: var seq[Element]) =
    if temp.kind notin discardTypes:
      res.add(temp)
    temp = Element(kind: Whitespace, token: "")

  proc save(res: var seq[Element], kind: ElementKind, str: string, compatibleTypes: set[ElementKind]) =
    if temp.kind notin compatibleTypes:
      flush(res)
      temp.kind = kind
    elif temp.kind == Dispatch:
      temp.kind = kind
    temp.token &= str

  for rune in code.runes:
    let
      str = $rune
      ch = str[0]
      esc = escaping
    escaping = (not escaping and ch == backslash)

    # deal with types that can contain a stream of arbitrary characters
    case temp.kind:
    of Character:
      if ch in invalidAfterCharacter or (ch == semicolon and temp.token.len > 1):
        flush(result)
      else:
        temp.token &= str
        continue
    of Comment:
      if ch == newline:
        flush(result)
      else:
        temp.token &= str
        continue
    of String:
      temp.token &= str
      if ch == doublequote and not esc:
        flush(result)
      continue
    else:
      discard

    # fast path for ascii chars
    if str.len == 1:
      case ch:
      of delims:
        if ch == '{':
          save(result, Delimiter, str, {Dispatch})
        else:
          save(result, Delimiter, str, {})
        continue
      of digits:
        save(result, Number, str, {Number, Symbol})
        continue
      of whitespace:
        save(result, Whitespace, str, {Whitespace})
        continue
      of colon:
        save(result, Keyword, str, {Keyword})
        continue
      of hash:
        save(result, Dispatch, str, {Symbol, Keyword})
        continue
      of specialCharacters:
        save(result, Special, str, {})
        continue
      of semicolon:
        save(result, Comment, str, {})
        continue
      of doublequote:
        save(result, String, str, {})
        continue
      of backslash:
        save(result, Character, str, {})
        continue
      else:
        discard

    # all other chars
    save(result, Symbol, str, {Symbol, Number, Keyword, Dispatch})

  flush(result)
