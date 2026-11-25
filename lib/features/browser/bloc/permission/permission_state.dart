part of 'permission_bloc.dart';

/// A request waiting for the user.
class PendingPermission extends Equatable {
  final String tabId;
  final WebViewController controller;
  final WebviewPermissionRequest request;

  /// Normalized requesting origin.
  final String origin;
  final List<SitePermissionKind> kinds;
  final bool isPrivate;

  const PendingPermission({
    required this.tabId,
    required this.controller,
    required this.request,
    required this.origin,
    required this.kinds,
    required this.isPrivate,
  });

  String get displayHost => displayHostForOrigin(origin);

  @override
  List<Object?> get props => [
    tabId,
    controller,
    request,
    origin,
    kinds,
    isPrivate,
  ];
}

class PermissionState extends Equatable {
  /// Requests waiting for an answer, oldest first.
  final List<PendingPermission> pending;

  const PermissionState({this.pending = const []});

  /// The request to show for [tabId], if any.
  PendingPermission? promptFor(String? tabId) {
    if (tabId == null) return null;
    for (final p in pending) {
      if (p.tabId == tabId) return p;
    }
    return null;
  }

  PermissionState copyWith({List<PendingPermission>? pending}) {
    return PermissionState(pending: pending ?? this.pending);
  }

  @override
  List<Object?> get props => [pending];
}
