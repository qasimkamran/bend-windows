// TCP
// ===

Term tcp_listen_run(Env e, Term* f, IoWork* w) {
  struct sockaddr_in at;
  u64 len;
  char* host = io_cstr(e, f[0], &len);
  int valid = !io_nul(host, len) && io_sys_addr(host, (u32)f[1], &at) == 0;
  free(host);
  if (!valid) {
    return io_fail(e, EINVAL, NULL);
  }
  IoSocket fd = io_net_socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    return io_fail(e, (uint32_t)errno, NULL);
  }
  int one = 1;
  io_net_setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
  int bound = io_net_bind(fd, (struct sockaddr*)&at, sizeof(at));
  if (bound < 0 || io_net_listen(fd, 512) < 0
    || io_socket_nonblock(fd) < 0) {
    uint32_t code = (uint32_t)errno;
    io_socket_close(fd);
    return io_fail(e, code, NULL);
  }
  return io_done(e, io_hand(fd));
}

static void __attribute__((constructor)) tcp_listen_use(void) {
  io_eff(CID(TCP.listen), tcp_listen_run, 0);
}
