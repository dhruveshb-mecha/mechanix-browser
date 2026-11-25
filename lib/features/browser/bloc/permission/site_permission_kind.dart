import 'package:webview_cef/webview_cef.dart';

/// Permission kinds the user sees and can remember per site.
enum SitePermissionKind {
  camera,
  microphone,
  location,
  notifications,
  clipboard,
  midi,
}

extension SitePermissionKindStore on SitePermissionKind {
  /// The decision Chromium itself remembers for this kind, or null when it
  /// keeps none (camera and microphone requests are asked every time).
  StoredPermission? get chromiumSetting => switch (this) {
    SitePermissionKind.location => StoredPermission.geolocation,
    SitePermissionKind.notifications => StoredPermission.notifications,
    SitePermissionKind.clipboard => StoredPermission.clipboard,
    SitePermissionKind.midi => StoredPermission.midi,
    SitePermissionKind.camera || SitePermissionKind.microphone => null,
  };
}

/// Result of mapping a raw CEF request mask onto [SitePermissionKind]s.
class ClassifiedPermissionRequest {
  /// Kinds the user can be asked about, in display order.
  final List<SitePermissionKind> kinds;

  /// True when the mask contains something this browser cannot back with a
  /// working implementation (screen capture, sensors, ...).
  /// Such requests are denied without prompting.
  final bool hasUnsupported;

  const ClassifiedPermissionRequest(this.kinds, this.hasUnsupported);
}

ClassifiedPermissionRequest classifyPermissionRequest(
  WebviewPermissionRequest request,
) {
  final kinds = <SitePermissionKind>{};
  var remaining = request.permissions;

  void map(int bit, SitePermissionKind kind) {
    if ((remaining & bit) != 0) {
      kinds.add(kind);
      remaining &= ~bit;
    }
  }

  if (request.isMedia) {
    map(MediaPermission.deviceVideoCapture, SitePermissionKind.camera);
    map(MediaPermission.deviceAudioCapture, SitePermissionKind.microphone);
    // Desktop audio/video capture stays in |remaining|: there is no source
    // picker in this windowless (Alloy) embedding, so screen sharing is
    // unsupported.
  } else {
    map(PromptPermission.cameraStream, SitePermissionKind.camera);
    map(PromptPermission.cameraPanTiltZoom, SitePermissionKind.camera);
    map(PromptPermission.micStream, SitePermissionKind.microphone);
    map(PromptPermission.geolocation, SitePermissionKind.location);
    map(PromptPermission.clipboard, SitePermissionKind.clipboard);
    map(PromptPermission.midiSysex, SitePermissionKind.midi);
    // Granted notifications are shown by Chromium itself through the
    // session's org.freedesktop.Notifications service.
    map(PromptPermission.notifications, SitePermissionKind.notifications);
  }

  final ordered = SitePermissionKind.values.where(kinds.contains).toList();
  return ClassifiedPermissionRequest(ordered, remaining != 0);
}

/// Decides a request from remembered decisions alone.
/// Returns false if any kind is blocked, true if every kind is allowed, and
/// null when the user has to be asked.
bool? resolveFromRemembered(
  List<SitePermissionKind> kinds,
  Map<SitePermissionKind, bool> remembered,
) {
  if (kinds.isEmpty) return false;
  if (kinds.any((k) => remembered[k] == false)) return false;
  if (kinds.every((k) => remembered[k] == true)) return true;
  return null;
}

/// Normalizes an origin as reported by CEF (`https://a.com/`) or a page URL
/// (`https://a.com/path?x`) to `scheme://host[:port]`.
String normalizeOrigin(String originOrUrl) {
  final trimmed = originOrUrl.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
  return uri.hasPort
      ? '${uri.scheme}://${uri.host}:${uri.port}'
      : '${uri.scheme}://${uri.host}';
}

/// Host to show in the UI for a normalized origin.
String displayHostForOrigin(String origin) {
  final uri = Uri.tryParse(origin);
  if (uri == null || uri.host.isEmpty) return origin;
  return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
}
