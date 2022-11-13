from limalisppkg/read import nil
from limalisppkg/eval import nil

when isMainModule:
  while true:
    stdout.write "=> "
    for cell in read.read(stdin.readLine):
      echo eval.eval(cell)
