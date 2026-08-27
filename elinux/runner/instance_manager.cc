#include "instance_manager.h"

#include <fcntl.h>
#include <sys/file.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <thread>
#include <iostream>

namespace {

std::string GetRuntimeDir() {
  const char* runtime_dir = std::getenv("XDG_RUNTIME_DIR");
  return runtime_dir ? runtime_dir : "/tmp";
}

std::string GetLockPath() {
  return GetRuntimeDir() + "/mechanix_browser.lock";
}

std::string GetSocketPath() {
  return GetRuntimeDir() + "/mechanix_browser.sock";
}

sockaddr_un MakeAddr(const std::string& path) {
  sockaddr_un addr{};
  addr.sun_family = AF_UNIX;
  std::strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);
  return addr;
}

int g_listen_fd = -1;
int g_lock_fd = -1;  // held for the lifetime of the primary process

}  // namespace

bool TryBecomePrimaryOrForward(const std::string& url_arg) {
  const std::string lock_path = GetLockPath();
  const std::string sock_path = GetSocketPath();

  // 1. Try to grab an exclusive, non-blocking lock. This is the ONLY
  //    thing that decides who's primary — atomic at the kernel level,
  //    so two processes racing here can never both "win".
  g_lock_fd = open(lock_path.c_str(), O_CREAT | O_RDWR, 0600);
  if (g_lock_fd < 0) {
    std::cerr << "[instance_manager] failed to open lockfile" << std::endl;
    return true;  // fail open — don't block app startup
  }

  if (flock(g_lock_fd, LOCK_EX | LOCK_NB) != 0) {
    // Someone else holds the lock — they're primary. Forward the URL
    // over the socket (best-effort) and exit.
    close(g_lock_fd);
    g_lock_fd = -1;

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd >= 0) {
      sockaddr_un addr = MakeAddr(sock_path);
      if (connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0) {
        if (!url_arg.empty()) {
          std::string payload = url_arg + "\n";
          send(fd, payload.c_str(), payload.size(), 0);
        }
      }
      close(fd);
    }
    return false;  // caller: exit(0) immediately
  }

  // 2. We hold the lock — we ARE primary, unambiguously. Now it's safe
  //    to clean up any stale socket from a previous crash and bind fresh.
  unlink(sock_path.c_str());

  g_listen_fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (g_listen_fd < 0) return true;

  sockaddr_un addr = MakeAddr(sock_path);
  if (bind(g_listen_fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
    std::cerr << "[instance_manager] bind failed on " << sock_path << std::endl;
    close(g_listen_fd);
    g_listen_fd = -1;
    // Still primary (we hold the lock) — just no IPC for later launches.
    return true;
  }
  listen(g_listen_fd, 8);
  return true;
}

void StartInstanceListener(std::function<void(std::string)> on_url) {
  if (g_listen_fd < 0) return;

  std::thread([on_url]() {
    while (true) {
      int client_fd = accept(g_listen_fd, nullptr, nullptr);
      if (client_fd < 0) continue;

      char buf[2048] = {0};
      ssize_t n = read(client_fd, buf, sizeof(buf) - 1);
      close(client_fd);

      if (n > 0) {
        std::string url(buf, n);
        while (!url.empty() && (url.back() == '\n' || url.back() == '\r')) {
          url.pop_back();
        }
        if (!url.empty()) {
          on_url(url);
        }
      }
    }
  }).detach();
}