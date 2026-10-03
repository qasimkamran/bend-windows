# Both pipe readers enforce the combined stdout/stderr limit and terminate
# a child that keeps running after producing too much output.
import Base

def limited(r: Result<&1, &1, U32 & String,
  U32 & (String & String)>) -> Bool:
  match r:
    case Done{value}:
      False{}
    case Fail{(code, message)}:
      U32.is_eq(code, 27)

def main() -> IO(Unit):
  do IO<Unit>:
    a : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("bun", ["-e", "process.stdout.write('x'.repeat(4096)); setTimeout(() => {}, 30000)"],
        "", 128, 5000)
    Unit <- IO.print("stdout limit: " ++ Bool.show(limited(a)))
    b : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("bun", ["-e", "process.stderr.write('x'.repeat(4096)); setTimeout(() => {}, 30000)"],
        "", 128, 5000)
    Unit <- IO.print("stderr limit: " ++ Bool.show(limited(b)))
    c : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("bun", ["-e", "process.stdout.write('x'.repeat(80)); process.stderr.write('y'.repeat(80)); setTimeout(() => {}, 30000)"],
        "", 128, 5000)
    IO.print("combined limit: " ++ Bool.show(limited(c)))

#|stdout limit: True
#|stderr limit: True
#|combined limit: True
