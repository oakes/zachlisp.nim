import unicode
import tables

type
  ElementKind* = enum
    Collection,
    Whitespace,
    OpenDelimiter,
    CloseDelimiter,
    Symbol,
    Number,
    Keyword,
    Dispatch,
    Special,
    Comment,
    String,
    Character,
  ErrorKind* = enum
    None,
    UnmatchedDelimiter,
    NoClosingDelimiter,
  Element* = object
    case kind*: ElementKind
    of Collection:
      elements*: seq[Element]
    else:
      token*: string
    error*: ErrorKind

const
  openDelims = {'(', '[', '{'}
  closeDelims = {')', ']', '}'}
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
  delimPairs = {
    "(": ")",
    "[": "]",
    "{": "}",
    "#{": "}",
  }.toTable

func `==`*(a, b: Element): bool =
  if a.kind == b.kind:
    case a.kind:
    of Collection:
      a.elements == b.elements and a.error == b.error
    else:
      a.token == b.token and a.error == b.error
  else:
    false

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
      of openDelims:
        if ch == '{':
          save(result, OpenDelimiter, str, {Dispatch})
        else:
          save(result, OpenDelimiter, str, {})
        continue
      of closeDelims:
        save(result, CloseDelimiter, str, {})
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

func parse*(elements: seq[Element], index: var int, elem: Element): seq[Element]

func parseCollection*(elements: seq[Element], index: var int, delimiter: Element): Element =
  result = Element(kind: Collection, elements: @[delimiter])
  let closeDelim = delimPairs[delimiter.token]
  while index < elements.len:
    let elem = elements[index]
    index += 1
    case elem.kind:
    of CloseDelimiter:
      if elem.token == closeDelim:
        result.elements.add(elem)
        return
      else:
        index -= 1
        result.error = UnmatchedDelimiter
        return
    else:
      result.elements &= parse(elements, index, elem)
  result.error = NoClosingDelimiter

func parse*(elements: seq[Element], index: var int, elem: Element): seq[Element] =
  case elem.kind:
  of OpenDelimiter:
    result.add(parseCollection(elements, index, elem))
  else:
    result.add(elem)

func parse*(elements: seq[Element], index: var int): seq[Element] =
  while index < elements.len:
    let elem = elements[index]
    index += 1
    result &= parse(elements, index, elem)

func parse*(elements: seq[Element]): seq[Element] =
  var index = 0
  parse(elements, index)

func readString*(code: string): seq[Element] =
  code.lex().parse()
