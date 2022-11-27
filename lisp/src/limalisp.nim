from ./limalisppkg/read import nil
from ./limalisppkg/eval import nil
from ./limalisppkg/print import nil
from ./limalisppkg/types import nil

when isMainModule:
  var ctx = eval.initContext()
  while true:
    stdout.write "=> "
    for cell in read.read(stdin.readLine):
      let ret = print.print(ctx, eval.eval(ctx, cell))
      if ret.kind == types.String:
        echo ret.stringVal
      else:
        echo ret
