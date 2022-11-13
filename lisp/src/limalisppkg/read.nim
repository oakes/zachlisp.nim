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
    SpecialSymbol,
    Comment,
    String,
    Character,
  ErrorKind* = enum
    None,
    NoMatchingOpenDelimiter,
    NoMatchingCloseDelimiter,
    NothingValidAfter,
    NoMatchingUnquote,
  Element* = object
    case kind*: ElementKind
    of Collection, SpecialPair:
      elements*: seq[Element]
    else:
      token*: string
      position*: tuple[line: int, column: int]
    error*: ErrorKind

const
  openDelims = {'(', '[', '{'}
  closeDelims = {')', ']', '}'}
  digits = {'0'..'9'}
  whitespace = {' ', '\t', '\r', '\n', ','}
  hash = '#'
  colon = ':'
  specialCharacters = {'^', '\'', '`', '~', '@'}
  newline = '\n'
  semicolon = ';'
  doublequote = '"'
  backslash = '\\'
  underscore = '_'
  invalidAfterCharacter = {' ', '\t', '\r', '\n'}
  delimPairs = {
    "(": ")",
    "[": "]",
    "{": "}",
    "#{": "}",
  }.toTable
  emptyElement = Element(kind: Whitespace, token: "")
  specialSymbolElement = Element(kind: SpecialSymbol, token: $hash)

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
    temp = emptyElement
    escaping = false
    line = 1
    column = 1

  proc flush(res: var seq[Element]) =
    if temp != emptyElement and temp.kind notin discardTypes:
      res.add(temp)
    temp = emptyElement

  proc save(res: var seq[Element], elem: Element, compatibleTypes: set[ElementKind]) =
    if temp.kind in compatibleTypes:
      temp.token &= elem.token
    else:
      flush(res)
      temp = elem

  for rune in code.runes:
    let
      str = $rune
      ch = str[0]
      esc = escaping
      position = (line: line, column: column)

    escaping = (not escaping and ch == backslash)

    if ch == newline:
      line += 1
      column = 1
    else:
      column += 1

    # deal with types that can contain a stream of arbitrary characters
    case temp.kind:
    of Character:
      if ch in invalidAfterCharacter or (ch == semicolon and temp.token.len > 1):
        if temp.token.len == 1:
          temp.error = NothingValidAfter
        flush(result)
      else:
        temp.token &= str
        continue
    of Comment:
      if ch != newline:
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
        if ch == '{' and temp == specialSymbolElement:
          temp = Element(kind: OpenDelimiter, token: temp.token & str, position: temp.position)
        else:
          save(result, Element(kind: OpenDelimiter, token: str, position: position), {})
        continue
      of closeDelims:
        save(result, Element(kind: CloseDelimiter, token: str, position: position), {})
        continue
      of digits:
        save(result, Element(kind: Number, token: str, position: position), {Number, Symbol, Keyword})
        continue
      of whitespace:
        save(result, Element(kind: Whitespace, token: str, position: position), {Whitespace})
        continue
      of colon:
        save(result, Element(kind: Keyword, token: str, position: position), {Keyword})
        continue
      of specialCharacters:
        save(result, Element(kind: SpecialCharacter, token: str, position: position), {SpecialCharacter})
        continue
      of hash:
        save(result, Element(kind: SpecialSymbol, token: str, position: position), {Symbol, Keyword})
        continue
      of semicolon:
        save(result, Element(kind: Comment, token: str, position: position), {})
        continue
      of doublequote:
        save(result, Element(kind: String, token: str, position: position), {})
        continue
      of backslash:
        save(result, Element(kind: Character, token: str, position: position), {})
        continue
      of underscore:
        if temp == specialSymbolElement:
          temp = Element(kind: SpecialSymbol, token: temp.token & str, position: position)
          flush(result)
          continue
      else:
        discard

    # all other chars
    save(result, Element(kind: Symbol, token: str, position: position), {Symbol, Number, Keyword, SpecialSymbol})

  if temp.kind == String:
    temp.error = NoMatchingUnquote

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
    if elem.kind in {SpecialCharacter, SpecialSymbol}:
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

func read*(code: string): seq[Element] =
  code.lex().parse()
