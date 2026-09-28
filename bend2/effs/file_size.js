// File
// ====

function file_size(file) {
  const fs = require("fs");
  try {
    const size = fs.fstatSync(file).size;
    const over = process.platform === "win32" ? 75
      : io_sys().mac ? 84 : 75;
    return io_tup(file, size > 4294967295 ? io_fail(over) : io_done(size));
  } catch (e) {
    const code = ({ EBADF: 9, EINVAL: 22 }[e.code]
      ?? Math.abs(e.errno ?? 5));
    return io_tup(file, io_fail(code));
  }
}

io_eff(CID(File.size), file_size);
