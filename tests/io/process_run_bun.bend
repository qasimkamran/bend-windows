# Process.run executes a Bun child without a shell, sends stdin, captures
# stdout and stderr separately, preserves the exit code, and enforces timeout.
import Base

def answer(r: Result<&1, &1, U32 & String, U32 & (String & String)>,
  want: U32, out: String, err: String) -> Bool:
  match r:
    case Done{(code, (stdout, stderr))}:
      Bool.and(U32.is_eq(code, want),
        Bool.and(String.eq(stdout, out), String.eq(stderr, err)))
    case Fail{error}:
      False{}

def timed_out(r: Result<&1, &1, U32 & String,
  U32 & (String & String)>) -> Bool:
  match r:
    case Done{value}:
      False{}
    case Fail{(+code, message)}:
      Bool.or(U32.is_eq(code, 60), U32.is_eq(code, 110))

def main() -> IO(Unit):
  do IO<Unit>:
    a : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("bun", ["-e", "const fs=require('fs'); process.stdout.write(fs.readFileSync(0,'utf8')); process.stderr.write('err'); process.exit(7)"],
        "input", 128, 5000)
    x : Unit <- IO.print("stdio and exit: " ++
      Bool.show(answer(a, 7, "input", "err")))
    b : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("bun", ["-e", "setTimeout(() => {}, 5000)"],
        "", 128, 500)
    IO.print("timeout: " ++ Bool.show(timed_out(b)))

#|stdio and exit: True
#|timeout: True
