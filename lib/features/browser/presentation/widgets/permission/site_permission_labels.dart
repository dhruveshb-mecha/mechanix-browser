import 'package:flutter/material.dart';
import 'package:mechanix_browser/features/browser/bloc/permission/site_permission_kind.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

extension SitePermissionKindLabels on SitePermissionKind {
  IconData get icon => switch (this) {
    SitePermissionKind.camera => Icons.videocam_outlined,
    SitePermissionKind.microphone => Icons.mic_none_outlined,
    SitePermissionKind.location => Icons.location_on_outlined,
    SitePermissionKind.notifications => Icons.notifications_none_outlined,
    SitePermissionKind.clipboard => Icons.content_paste_outlined,
    SitePermissionKind.midi => Icons.piano_outlined,
  };

  /// Short name, e.g. "Camera".
  String label(AppLocalizations l10n) => switch (this) {
    SitePermissionKind.camera => l10n.permissionCamera,
    SitePermissionKind.microphone => l10n.permissionMicrophone,
    SitePermissionKind.location => l10n.permissionLocation,
    SitePermissionKind.notifications => l10n.permissionNotifications,
    SitePermissionKind.clipboard => l10n.permissionClipboard,
    SitePermissionKind.midi => l10n.permissionMidi,
  };

  /// Prompt line completing "`host` wants to", e.g. "Use your camera".
  String requestLabel(AppLocalizations l10n) => switch (this) {
    SitePermissionKind.camera => l10n.permissionCameraRequest,
    SitePermissionKind.microphone => l10n.permissionMicrophoneRequest,
    SitePermissionKind.location => l10n.permissionLocationRequest,
    SitePermissionKind.notifications => l10n.permissionNotificationsRequest,
    SitePermissionKind.clipboard => l10n.permissionClipboardRequest,
    SitePermissionKind.midi => l10n.permissionMidiRequest,
  };
}
