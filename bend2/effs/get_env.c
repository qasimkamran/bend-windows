// IO
// ==

Term io_get_env_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* name = io_cstr(e, f[0], &n);
#ifdef _WIN32
  int wn = io_nul(name, n) ? 0
    : MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name, -1, NULL, 0);
  wchar_t* wide = wn > 0 ? io_mem(malloc((size_t)wn * sizeof(wchar_t))) : NULL;
  if (wn > 0 && MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, name,
    -1, wide, wn) != wn) {
    free(wide);
    wide = NULL;
  }
  const wchar_t* value = wide == NULL ? NULL : _wgetenv(wide);
  free(wide);
  free(name);
  if (value == NULL) return io_fail(e, ENOENT, NULL);
  int bytes = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, value, -1,
    NULL, 0, NULL, NULL);
  if (bytes <= 0) return io_fail(e, EILSEQ, NULL);
  char* utf8 = io_mem(malloc((size_t)bytes));
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, value, -1, utf8,
    bytes, NULL, NULL) != bytes) {
    free(utf8);
    return io_fail(e, EILSEQ, NULL);
  }
  Term out = io_done(e, io_str(e, utf8, (uint64_t)bytes - 1));
  free(utf8);
  return out;
#else
  const char* got = io_nul(name, n) ? NULL : getenv(name);
  free(name);
  return got == NULL ? io_fail(e, ENOENT, NULL)
    : io_done(e, io_str(e, got, strlen(got)));
#endif
}

static void __attribute__((constructor)) io_get_env_use(void) {
  io_eff(CID(IO.get_env), io_get_env_run, 0);
}
