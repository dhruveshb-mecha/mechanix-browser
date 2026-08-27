#pragma once
#include <string>
#include <functional>

// Returns true if THIS process became the primary instance (should continue
// normal startup). Returns false if a URL was successfully forwarded to an
// already-running instance (caller should exit immediately).
bool TryBecomePrimaryOrForward(const std::string& url_arg);

// Call once, after the Flutter engine is up, to start accepting URLs from
// future secondary launches. on_url is invoked (on the accept thread) for
// each incoming URL.
void StartInstanceListener(std::function<void(std::string)> on_url);
