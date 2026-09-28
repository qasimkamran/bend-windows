// Small POSIX dynamic-loader compatibility layer for foreign C imports on
// Windows. It lets portable C effects use the familiar dlfcn API while the
// implementation delegates to the Windows loader.
#ifndef BEND_DLFCN_H
#define BEND_DLFCN_H

#ifdef _WIN32
#include <windows.h>

#define RTLD_LAZY 0
#define RTLD_NOW 0
#define RTLD_LOCAL 0
#define RTLD_GLOBAL 0

static inline void* dlopen(const char* filename, int flags) {
  (void)flags;
  return (void*)LoadLibraryA(filename);
}

static inline void* dlsym(void* handle, const char* symbol) {
  return (void*)GetProcAddress((HMODULE)handle, symbol);
}

static inline int dlclose(void* handle) {
  return FreeLibrary((HMODULE)handle) ? 0 : -1;
}

static inline const char* dlerror(void) {
  return "Windows dynamic loader error";
}
#else
#include_next <dlfcn.h>
#endif

#endif
