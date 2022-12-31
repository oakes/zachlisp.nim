You know what the world needs? Another Lisp. This one is written in Nim and has Clojure-style syntax, immutable data structures, a macro system and a very Clojure-inspired standard library (see [the tests](tests/test_eval.nim)).

To build and run the REPL:

```
nimble build -d:release

rlwrap ./zachlisp
```

To run the tests:

```
nimble test
```
