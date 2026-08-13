// elinux/runner/main.cc

#include <flutter/basic_message_channel.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/standard_message_codec.h>
#include <webview_cef/webview_cef_plugin.h>

#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "flutter_embedder_options.h"
#include "flutter_window.h"
#include "instance_manager.h"

namespace {
// Short flags that consume the *next* argv token as a value (e.g. "-s 1"),
// based on your --help output. Verify against flutter_embedder_options.h.
bool ShortFlagTakesValue(char c) {
  switch (c) {
    case 'b': case 'r': case 'x': case 's':
    case 't': case 'a': case 'w': case 'h':
      return true;
    default:
      return false;
  }
}
}  // namespace

int main(int argc, char** argv) {
  // --------------------------------------------------------------------
  // STEP 1: Let CEF inspect the RAW, untouched argv first.
  // CEF re-launches this same executable for its subprocesses
  // (renderer/gpu/zygote) with its own internal flags (e.g. --type=renderer).
  // If this returns >= 0, we ARE one of those subprocesses — just exit.
  // Do NOT run our custom arg-splitting logic before this call.
  // --------------------------------------------------------------------
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }

  // --------------------------------------------------------------------
  // STEP 2: We're the main browser process — now safe to split argv into
  // (a) engine/window flags consumed by FlutterEmbedderOptions, and
  // (b) everything else (e.g. the captive-portal/deep-link URL passed by
  //     xdg-open or your launcher) forwarded to Dart's main(args).
  // --------------------------------------------------------------------
  std::vector<std::string> engine_arg_storage;
  std::vector<std::string> dart_entrypoint_arguments;
  engine_arg_storage.push_back(argv[0]);

  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    if (arg.rfind("--", 0) == 0) {
      engine_arg_storage.push_back(arg);
    } else if (arg.size() >= 2 && arg[0] == '-' && arg != "-") {
      engine_arg_storage.push_back(arg);
      if (ShortFlagTakesValue(arg[1]) && i + 1 < argc) {
        engine_arg_storage.push_back(argv[++i]);  // consume its value too
      }
    } else {
      // Anything that isn't a flag — e.g. the URL from xdg-open — goes to Dart.
      dart_entrypoint_arguments.push_back(arg);
    }
  }

  std::vector<char*> engine_argv;
  for (auto& s : engine_arg_storage) {
    engine_argv.push_back(const_cast<char*>(s.c_str()));
  }

  FlutterEmbedderOptions options;
  if (!options.Parse(static_cast<int>(engine_argv.size()), engine_argv.data())) {
    return 0;
  }

  const auto bundle_path = options.BundlePath();
  const std::wstring fl_path(bundle_path.begin(), bundle_path.end());
  flutter::DartProject project(fl_path);

  // Forward the extracted URL (or any other non-flag args) into Dart's main().
  std::string incoming_url = dart_entrypoint_arguments.empty() ? "" : dart_entrypoint_arguments.front();
  if (!TryBecomePrimaryOrForward(incoming_url)) {
    return 0;
  }

  project.set_dart_entrypoint_arguments(std::move(dart_entrypoint_arguments));

  flutter::FlutterViewController::ViewProperties view_properties = {};
  view_properties.width = options.WindowWidth();
  view_properties.height = options.WindowHeight();
  view_properties.view_mode = options.WindowViewMode();
  view_properties.view_rotation = options.WindowRotation();
  view_properties.title = options.WindowTitle();
  view_properties.app_id = options.WindowAppID();
  view_properties.use_mouse_cursor = options.IsUseMouseCursor();
  view_properties.use_onscreen_keyboard = options.IsUseOnscreenKeyboard();
  view_properties.use_window_decoration = options.IsUseWindowDecoraation();
  view_properties.text_scale_factor = options.TextScaleFactor();
  view_properties.enable_high_contrast = options.EnableHighContrast();
  view_properties.force_scale_factor = options.IsForceScaleFactor();
  view_properties.scale_factor = options.ScaleFactor();
  view_properties.enable_vsync = options.EnableVsync();

  FlutterWindow window(view_properties, project);
  if (!window.OnCreate()) {
    return 0;
  }

  StartInstanceListener([&window](std::string url) {
    auto messenger = window.GetEngine()->messenger();
    flutter::BasicMessageChannel<flutter::EncodableValue> channel(
        messenger, "com.mechanix.browser/singleton",
        &flutter::StandardMessageCodec::GetInstance());
    channel.Send(flutter::EncodableValue(url));
  });

  window.Run();
  window.OnDestroy();
  return 0;
}