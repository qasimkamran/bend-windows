// File
// ====

static int file_open_mode(const char* mode) {
  if (strcmp(mode, "r") == 0) {
    return O_RDONLY;
  }
  if (strcmp(mode, "w") == 0) {
    return O_WRONLY | O_CREAT | O_TRUNC;
  }
  if (strcmp(mode, "a") == 0) {
    return O_WRONLY | O_CREAT | O_APPEND;
  }
  return -1;
}

static void file_open_call(IoWork* w) {
#ifdef _WIN32
  int n = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, w->data, -1,
    NULL, 0);
  if (n <= 0) {
    io_sys_end(w, -1);
    w->code = EILSEQ;
    return;
  }
  WCHAR* path = io_mem(malloc((size_t)n * sizeof(WCHAR)));
  if (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, w->data, -1,
    path, n) != n) {
    free(path);
    io_sys_end(w, -1);
    w->code = EILSEQ;
    return;
  }
  int flags = (int)w->word;
  DWORD access = flags & O_WRONLY ? GENERIC_WRITE : GENERIC_READ;
  DWORD make = flags & O_TRUNC ? CREATE_ALWAYS
    : flags & O_CREAT ? OPEN_ALWAYS : OPEN_EXISTING;
  HANDLE h = CreateFileW(path, access,
    FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
    NULL, make, FILE_ATTRIBUTE_NORMAL, NULL);
  free(path);
  if (h == INVALID_HANDLE_VALUE) {
    DWORD err = GetLastError();
    errno = err == ERROR_FILE_NOT_FOUND || err == ERROR_PATH_NOT_FOUND
      ? ENOENT : err == ERROR_ACCESS_DENIED ? EACCES : EIO;
    io_sys_end(w, -1);
    return;
  }
  int mode = _O_BINARY | (flags & O_WRONLY ? _O_WRONLY : _O_RDONLY)
    | (flags & O_APPEND ? _O_APPEND : 0);
  int fd = _open_osfhandle((intptr_t)h, mode);
  if (fd < 0) CloseHandle(h);
  w->made = (intptr_t)io_sys_end(w, fd);
#else
  w->made = (intptr_t)io_sys_end(w, open(w->data, (int)w->word, 0644));
#endif
}

static Term file_open_pack(Env e, IoWork* w) {
  free(w->data);
  return io_res(e, w, io_hand(w->made));
}

Term file_open_run(Env e, Term* f, IoWork* w) {
  uint64_t mn = 0;
  w->data = io_cstr(e, f[0], &w->size);
  char* mode = io_cstr(e, f[1], &mn);
  int flags = io_nul(mode, mn) ? -1 : file_open_mode(mode);
  free(mode);
  w->word = (uint32_t)flags;
  if (io_nul(w->data, w->size) || flags < 0) {
    w->code = io_nul(w->data, w->size) ? EILSEQ : EINVAL;
    return file_open_pack(e, w);
  }
  return io_work(w, file_open_call, file_open_pack);
}

static void __attribute__((constructor)) file_open_use(void) {
  io_eff(CID(File.open), file_open_run, 0);
}
