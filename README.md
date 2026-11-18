# mechanix-browser

Browser for Mechanix OS. A Flutter app for [flutter-elinux](https://github.com/flutter-elinux/flutter-elinux) (Wayland), with pages rendered by CEF through [webview_cef](https://github.com/mecha-org/webview_cef).

## Setup

| Requirement | Notes |
|---|---|
| flutter-elinux **3.47.1** | Same version as CI. Expected at `/opt/flutter-elinux`: `export PATH=/opt/flutter-elinux/bin:$PATH` |
| `libsqlite3-dev` | Needed to build: the runner links the system SQLite (see [SQLite on elinux](#sqlite-on-elinux)) |
| `libsqlite3-0` / `sqlite-libs` | Needed at runtime. The deb and rpm packages depend on it |

```sh
flutter-elinux pub get
flutter-elinux run -d elinux-wayland            
flutter-elinux build elinux --release           
```

To run a built bundle directly:

```sh
cd build/elinux/x64/release/bundle
DEBUG_LOG=info ./mechanix_browser --bundle=. [url]
```

- **`DEBUG_LOG`:** release builds log nothing unless this is set (`debug`, `info`, `warn` or `error`).
- **Isolated profile:** set `HOME=/tmp/some-dir` to try the app without touching your real data.

## Where data lives

All browser data is in `~/.config/mechanix_apps/browser/` (`AppConstants.profileDir`):

| File | Contents | Code |
|---|---|---|
| `browser.sqlite` (+ `-wal`, `-shm`) | History, downloads, open tabs | `lib/core/database/app_database.dart` |
| `Bookmarks` | Bookmarks and favorites (JSON) | `lib/features/browser/data/bookmarks/bookmark_model.dart` |
| `Bookmarks.bak` | The previous `Bookmarks`, copied once per session before the first write | |
| `Bookmarks.corrupt` | An unreadable `Bookmarks`, kept aside; the app loads `.bak` instead | |
