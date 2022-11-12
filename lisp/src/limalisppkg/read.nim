import unicode

type
  ElementKind* = enum
    Whitespace,
    Delimiter,
    Symbol,
    Number,
    Dispatch,
    Keyword,
  Element* = object
    kind*: ElementKind
    token*: string

const
  delims = {'(', ')', '[', ']', '{', '}'}
  digits = {'0'..'9'}
  whitespace = {' ', '\t', ','}
  hash = '#'
  colon = ':'

func lex*(code: string, discardTypes: set[ElementKind] = {Whitespace}): seq[Element] =
  var temp = Element(kind: Whitespace, token: "")

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
    let str = $rune
    if str.len == 1:
      let ch = str[0]
      case ch:
      of delims:
        save(result, Delimiter, str, if ch == '{': {Dispatch} else: {})
        continue
      of digits:
        save(result, Number, str, {Number, Symbol})
        continue
      of whitespace:
        save(result, Whitespace, str, {Whitespace})
        continue
      of hash:
        save(result, Dispatch, str, {})
        continue
      of colon:
        save(result, Keyword, str, {Keyword})
        continue
      else:
        discard
    save(result, Symbol, str, {Symbol, Number, Dispatch, Keyword})
  flush(result)
