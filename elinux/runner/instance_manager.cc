#include "instance_manager.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstdlib>
#include <cstring>
#include <thread>
#include <iostream>

namespace {

std::string GetSocketPath() {
    const char* runtime_dir = std::getenv("XDG_RUNTIME_DIR");
    std::string base = runtime_dir ? runtime_dir : "/tmp";
    return base + "/mechanix_browser.sock";
}

sockaddr_un MakeAddr(const std::string& path) {
    sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);
    return addr;
}

int g_listen_fd = -1;

}  // namespace

bool TryBecomePrimaryOrForward(const std::string& url_arg) {
    const std::string sock_path = GetSocketPath();

    // 1. Try connecting — if something's already listening, we're secondary.
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return true;

    sockaddr_un addr = MakeAddr(sock_path);

    if (connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0) {
        // A primary instance is alive — hand off the URL and bail out.
        if (!url_arg.empty()) {
            std::string payload = url_arg + "\n";
            send(fd, payload.c_str(), payload.size(), 0);
        }
        close(fd);
        return false;  // caller: exit(0) immediately, skip Flutter/CEF init
    }
    close(fd);

    // 2. No one answered — remove any stale socket file (e.g. from a crash)
    //    and bind fresh as the primary instance.
    unlink(sock_path.c_str());

    g_listen_fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (g_listen_fd < 0) return true;

    if (bind(g_listen_fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
        std::cerr << "[instance_manager] bind failed on " << sock_path << std::endl;
        close(g_listen_fd);
        g_listen_fd = -1;
        // Fall through as primary anyway — worst case, no IPC for later
        // launches, but we don't want to block the app from starting.
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
                // strip trailing newline
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
