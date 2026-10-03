// File
// ====

function file_write_buffer(file, b) {
  const fs = require("fs");
  let at = 0;
  try {
    while (at < b.length) {
      at += fs.writeSync(file, b, at, b.length - at, null);
    }
    return io_tup(file, io_done({ $: CID(Unit) }));
  } catch (e) {
    const code = ({ EBADF: 9, EINVAL: 22, ENOSPC: 28, EPIPE: 32 }[e.code]
      ?? Math.abs(e.errno ?? 5));
    return io_tup(file, io_fail(code));
  }
}

function file_write(file, data) {
  return file_write_buffer(file, io_bytes(data));
}

function file_write_bytes(file, data) {
  const b = io_unlist(data);
  return b === null ? io_tup(file, io_fail(22)) : file_write_buffer(file, b);
}

io_eff(CID(File.write), file_write);
io_eff(CID(File.write_bytes), file_write_bytes);
