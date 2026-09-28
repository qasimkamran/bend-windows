// File
// ====

function file_read_with(file, max, offset, pack) {
  const len = Math.min(max, 2147483647);
  const b = new Uint8Array(Math.max(len, 1));
  if (process.platform !== "win32") {
    const sys = io_sys();
    const n = Number(offset === null ? sys.read(file, sys.ptr(b), len)
      : sys.pread(file, sys.ptr(b), len, BigInt(offset)));
    return io_tup(file, n < 0 ? io_fail(sys.errno()) : io_done(pack(b, n)));
  }
  try {
    const at = offset === null ? null : BigInt(offset);
    if (at !== null && at < 0n) {
      return io_tup(file, io_fail(22));
    }
    const n = require("fs").readSync(file, b, 0, len, at);
    return io_tup(file, io_done(pack(b, n)));
  } catch (e) {
    const code = ({ EBADF: 9, EINVAL: 22, EISDIR: 21 }[e.code]
      ?? Math.abs(e.errno ?? 5));
    return io_tup(file, io_fail(code));
  }
}

function file_read(file, max) {
  return file_read_with(file, max, null, io_text);
}

function file_read_bytes(file, max) {
  return file_read_with(file, max, null, io_list);
}

function file_read_at(file, offset, max) {
  return file_read_with(file, max, offset, io_list);
}

io_eff(CID(File.read), file_read);
io_eff(CID(File.read_bytes), file_read_bytes);
io_eff(CID(File.read_at), file_read_at);
