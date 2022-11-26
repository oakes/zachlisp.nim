from limalisppkg/read import nil
from limalisppkg/eval import nil

when isMainModule:
  while true:
    stdout.write "=> "
    for cell in read.read(stdin.readLine):
      let ret = eval.print(eval.eval(cell))
      if ret.kind == eval.String:
        echo ret.stringVal
      else:
        echo ret
