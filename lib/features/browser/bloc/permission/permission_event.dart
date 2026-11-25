part of 'permission_bloc.dart';

sealed class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object?> get props => [];
}

/// A page in [tabId] asked for a permission.
class PermissionRequested extends PermissionEvent {
  final String tabId;
  final WebViewController controller;
  final WebviewPermissionRequest request;
  final bool isPrivate;

  const PermissionRequested({
    required this.tabId,
    required this.controller,
    required this.request,
    required this.isPrivate,
  });

  @override
  List<Object?> get props => [tabId, controller, request, isPrivate];
}

/// CEF withdrew a request (navigation, browser closed).
class PermissionDismissed extends PermissionEvent {
  final WebViewController controller;
  final int requestId;
  final bool isMedia;

  const PermissionDismissed({
    required this.controller,
    required this.requestId,
    required this.isMedia,
  });

  @override
  List<Object?> get props => [controller, requestId, isMedia];
}

/// The user chose Allow or Block on the prompt. Chromium remembers prompt
/// permissions; camera and microphone are remembered while the tab stays on
/// the site.
class PermissionDecided extends PermissionEvent {
  final PendingPermission pending;
  final bool allow;

  const PermissionDecided(this.pending, {required this.allow});

  @override
  List<Object?> get props => [pending, allow];
}

/// The user closed the prompt without choosing. The request is denied this
/// time and nothing is remembered.
class PermissionPromptClosed extends PermissionEvent {
  final PendingPermission pending;

  const PermissionPromptClosed(this.pending);

  @override
  List<Object?> get props => [pending];
}

/// [tabId] navigated to [url]; requests from another origin are dropped.
class PermissionTabNavigated extends PermissionEvent {
  final String tabId;
  final String url;

  const PermissionTabNavigated({required this.tabId, required this.url});

  @override
  List<Object?> get props => [tabId, url];
}

/// A tab's webview is being disposed.
class PermissionControllerDisposed extends PermissionEvent {
  final WebViewController controller;

  const PermissionControllerDisposed(this.controller);

  @override
  List<Object?> get props => [controller];
}
