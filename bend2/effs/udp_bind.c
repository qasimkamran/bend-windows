// UDP
// ===

Term udp_bind_run(Env e, Term* f, IoWork* w) {
  struct sockaddr_in at;
  u64 len;
  char* host = io_cstr(e, f[0], &len);
  int valid = !io_nul(host, len) && io_sys_addr(host, (u32)f[1], &at) == 0;
  free(host);
  if (!valid) {
    return io_fail(e, EINVAL, NULL);
  }
  IoSocket fd = io_net_socket(AF_INET, SOCK_DGRAM, 0);
  if (fd < 0) {
    return io_fail(e, (uint32_t)errno, NULL);
  }
  if (io_net_bind(fd, (struct sockaddr*)&at, sizeof(at)) < 0
    || io_socket_nonblock(fd) < 0) {
    uint32_t code = (uint32_t)errno;
    io_socket_close(fd);
    return io_fail(e, code, NULL);
  }
  return io_done(e, io_hand(fd));
}

static void __attribute__((constructor)) udp_bind_use(void) {
  io_eff(CID(UDP.bind), udp_bind_run, 0);
}
