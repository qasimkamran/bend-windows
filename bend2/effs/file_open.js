// File
// ====

function file_open(path, mode) {
  if (path.includes("\0")) {
    return io_fail(process.platform === "win32" ? 22
      : process.platform === "darwin" ? 92 : 84);
  }
  const name = process.platform === "win32" ? path : io_bytes(path);
  if (!["r", "w", "a"].includes(mode)) {
    return io_fail(22);
  }
  try {
    const fd = require("fs")
      .openSync(typeof name === "string" ? name
        : name.length > 0 ? Buffer.from(name) : "", mode, 0o644);
    return io_done(fd);
  } catch (e) {
    const code = ({ ENOENT: 2, EACCES: 13, EBADF: 9, EEXIST: 17,
      ENOTDIR: 20, EISDIR: 21, EINVAL: 22, EMFILE: 24, ENOSPC: 28 }[e.code]
      ?? Math.abs(e.errno ?? 5));
    return io_fail(code);
  }
}

io_eff(CID(File.open), file_open);
