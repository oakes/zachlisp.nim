import unicode
import tables

type
  ElementKind* = enum
    Collection,
    SpecialPair,
    Whitespace,
    OpenDelimiter,
    CloseDelimiter,
    Symbol,
    Number,
    Keyword,
    SpecialCharacter,
    Comment,
    String,
    Character,
  ErrorKind* = enum
    None,
    NoMatchingOpenDelimiter,
    NoMatchingCloseDelimiter,
    NothingValidAfter,
  Element* = object
    case kind*: ElementKind
    of Collection, SpecialPair:
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
  dispatchElement = Element(kind: SpecialCharacter, token: $hash)
  colon = ':'
  specialCharacters = {'#', '^', '\'', '`', '~', '@'}
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
    of Collection, SpecialPair:
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

  proc save(res: var seq[Element], elem: Element, compatibleTypes: set[ElementKind]) =
    if temp.kind notin compatibleTypes:
      flush(res)
      let prefix = temp.token
      temp = elem
      temp.token = prefix & temp.token
    else:
      temp.token &= elem.token

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
        if ch == '{' and temp == dispatchElement:
          temp = Element(kind: OpenDelimiter, token: temp.token & str)
        else:
          save(result, Element(kind: OpenDelimiter, token: str), {})
        continue
      of closeDelims:
        save(result, Element(kind: CloseDelimiter, token: str), {})
        continue
      of digits:
        save(result, Element(kind: Number, token: str), {Number, Symbol})
        continue
      of whitespace:
        save(result, Element(kind: Whitespace, token: str), {Whitespace})
        continue
      of colon:
        save(result, Element(kind: Keyword, token: str), {Keyword})
        continue
      of specialCharacters:
        save(result, Element(kind: SpecialCharacter, token: str), {SpecialCharacter})
        continue
      of semicolon:
        save(result, Element(kind: Comment, token: str), {})
        continue
      of doublequote:
        save(result, Element(kind: String, token: str), {})
        continue
      of backslash:
        save(result, Element(kind: Character, token: str), {})
        continue
      else:
        discard

    # all other chars
    save(result, Element(kind: Symbol, token: str), {Symbol, Number, Keyword})

  flush(result)

func parse*(elements: seq[Element], index: var int): seq[Element]

func parseCollection*(elements: seq[Element], index: var int, delimiter: Element): seq[Element] =
  var coll = Element(kind: Collection, elements: @[delimiter])
  let closeDelim = delimPairs[delimiter.token]
  while index < elements.len:
    let elem = elements[index]
    case elem.kind:
    of CloseDelimiter:
      if elem.token == closeDelim:
        index += 1
        coll.elements.add(elem)
        return @[coll]
      else:
        coll.elements[0].error = NoMatchingCloseDelimiter
        return coll.elements
    else:
      coll.elements.add(parse(elements, index))
  coll.elements[0].error = NoMatchingCloseDelimiter
  coll.elements

func parse*(elements: seq[Element], index: var int): seq[Element] =
  if index == elements.len:
    return @[]

  let elem = elements[index]
  index += 1

  case elem.kind:
  of OpenDelimiter:
    parseCollection(elements, index, elem)
  of CloseDelimiter:
    var res = elem
    res.error = NoMatchingOpenDelimiter
    @[res]
  else:
    if elem.kind == SpecialCharacter:
      if index < elements.len:
        let nextElems = parse(elements, index)
        if nextElems.len == 1 and nextElems[0].error == None:
          @[Element(kind: SpecialPair, elements: @[elem] & nextElems)]
        else:
          index -= 1
          var res = elem
          res.error = NothingValidAfter
          @[res]
      else:
        var res = elem
        res.error = NothingValidAfter
        @[res]
    else:
      @[elem]

func parse*(elements: seq[Element]): seq[Element] =
  var index = 0
  while index < elements.len:
    result.add(parse(elements, index))

func readString*(code: string): seq[Element] =
  code.lex().parse()
