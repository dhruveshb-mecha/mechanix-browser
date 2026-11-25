import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/features/browser/bloc/permission/site_permission_kind.dart';
import 'package:webview_cef/webview_cef.dart';

part 'permission_event.dart';
part 'permission_state.dart';

/// Sends the answer for a request back to CEF.
typedef PermissionResponder =
    Future<void> Function(
      WebviewPermissionRequest request,
      bool allow, {
      PermissionPromptResult? promptResult,
    });

/// Reads the decision Chromium stored for an origin in the persistent profile.
typedef ChromiumPermissionReader =
    Future<StoredPermissionValue?> Function(
      String origin,
      StoredPermission permission,
    );

/// Handles camera, microphone, location, notification, clipboard and MIDI
/// requests from pages by queueing a prompt for the requesting tab.
///
/// Nothing is stored by the app:
/// - Chromium remembers prompt permissions (notifications, location, ...) in
///   its profile and only asks again when it has no decision.
/// - Camera and microphone decisions last while the tab stays on the site,
///   so a page asking several times (preview, join, switch device) is asked
///   once. A new visit asks again.
/// - Private tabs have their own empty profile, so they inherit blocks from
///   the normal profile here, but never allows.
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final PermissionResponder _respond;
  final ChromiumPermissionReader _readChromium;

  /// Decisions made in each tab for the site it is on, keyed by tab id.
  final Map<String, _TabDecisions> _tabDecisions = {};

  PermissionBloc({
    PermissionResponder? respond,
    ChromiumPermissionReader? readChromium,
  }) : _respond = respond ?? WebviewManager().respondToPermissionRequest,
       _readChromium = readChromium ?? WebviewManager().getPermissionSetting,
       super(const PermissionState()) {
    on<PermissionRequested>(_onRequested);
    on<PermissionDismissed>(_onDismissed);
    on<PermissionDecided>(_onDecided);
    on<PermissionPromptClosed>(_onPromptClosed);
    on<PermissionTabNavigated>(_onTabNavigated);
    on<PermissionControllerDisposed>(_onControllerDisposed);
  }

  Map<SitePermissionKind, bool> _decisionsFor(String tabId, String origin) {
    final tab = _tabDecisions[tabId];
    return tab != null && tab.origin == origin ? tab.decisions : const {};
  }

  /// True when the normal profile blocks any of [kinds] for [origin].
  Future<bool> _blockedInNormalProfile(
    String origin,
    List<SitePermissionKind> kinds,
  ) async {
    for (final kind in kinds) {
      final setting = kind.chromiumSetting;
      if (setting == null) continue;
      try {
        if (await _readChromium(origin, setting) ==
            StoredPermissionValue.block) {
          return true;
        }
      } catch (e, stackTrace) {
        AppLogger.e(
          'Unable to read Chromium permission $setting for $origin',
          error: e,
          stack: stackTrace,
        );
      }
    }
    return false;
  }

  Future<void> _answer(
    WebviewPermissionRequest request,
    bool allow, {
    PermissionPromptResult? promptResult,
  }) async {
    try {
      await _respond(request, allow, promptResult: promptResult);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Unable to answer permission request $request',
        error: e,
        stack: stackTrace,
      );
    }
  }

  Future<void> _onRequested(
    PermissionRequested event,
    Emitter<PermissionState> emit,
  ) async {
    final request = event.request;
    final origin = normalizeOrigin(request.origin);
    final classified = classifyPermissionRequest(request);

    if (classified.hasUnsupported || classified.kinds.isEmpty) {
      AppLogger.i(
        '[Permission] Denying unsupported request from $origin: $request',
      );
      await _answer(request, false);
      return;
    }

    final decision = resolveFromRemembered(
      classified.kinds,
      _decisionsFor(event.tabId, origin),
    );
    if (decision != null) {
      AppLogger.i(
        '[Permission] ${decision ? 'Allowing' : 'Blocking'} $origin ${classified.kinds.map((k) => k.name)} (this visit)',
      );
      await _answer(request, decision);
      return;
    }

    if (event.isPrivate &&
        await _blockedInNormalProfile(origin, classified.kinds)) {
      AppLogger.i('[Permission] Blocking $origin in private tab (inherited)');
      await _answer(request, false);
      return;
    }

    emit(
      state.copyWith(
        pending: [
          ...state.pending,
          PendingPermission(
            tabId: event.tabId,
            controller: event.controller,
            request: request,
            origin: origin,
            kinds: classified.kinds,
            isPrivate: event.isPrivate,
          ),
        ],
      ),
    );
  }

  void _onDismissed(PermissionDismissed event, Emitter<PermissionState> emit) {
    _removeWhere(
      emit,
      (p) =>
          p.controller == event.controller &&
          p.request.requestId == event.requestId &&
          p.request.isMedia == event.isMedia,
    );
  }

  Future<void> _onDecided(
    PermissionDecided event,
    Emitter<PermissionState> emit,
  ) async {
    final pending = event.pending;
    if (!state.pending.contains(pending)) return;

    var tab = _tabDecisions[pending.tabId];
    if (tab == null || tab.origin != pending.origin) {
      tab = _tabDecisions[pending.tabId] = _TabDecisions(
        controller: pending.controller,
        origin: pending.origin,
      );
    }
    final decisions = tab.decisions;
    for (final kind in pending.kinds) {
      decisions[kind] = event.allow;
    }

    _removeWhere(emit, (p) => p == pending);
    await _answer(pending.request, event.allow);

    // Other requests the decision now settles: duplicates in the same tab,
    // and prompt permissions from other normal tabs on the same site (they
    // share the profile Chromium just stored the answer in).
    final settled = <PendingPermission, bool>{};
    for (final other in state.pending) {
      if (other.origin != pending.origin) continue;
      final decision = other.tabId == pending.tabId
          ? resolveFromRemembered(other.kinds, decisions)
          : _sharedDecision(pending, other, event.allow);
      if (decision != null) settled[other] = decision;
    }
    if (settled.isNotEmpty) {
      _removeWhere(emit, settled.containsKey);
      for (final entry in settled.entries) {
        await _answer(entry.key.request, entry.value);
      }
    }
  }

  /// The answer [decided] gives to [other] in another tab, if it settles it.
  bool? _sharedDecision(
    PendingPermission decided,
    PendingPermission other,
    bool allow,
  ) {
    if (decided.isPrivate || other.isPrivate) return null;
    final storedByChromium = other.kinds.every(
      (k) => k.chromiumSetting != null && decided.kinds.contains(k),
    );
    return storedByChromium ? allow : null;
  }

  Future<void> _onPromptClosed(
    PermissionPromptClosed event,
    Emitter<PermissionState> emit,
  ) async {
    if (!state.pending.contains(event.pending)) return;
    _removeWhere(emit, (p) => p == event.pending);
    await _answer(
      event.pending.request,
      false,
      promptResult: PermissionPromptResult.dismiss,
    );
  }

  Future<void> _onTabNavigated(
    PermissionTabNavigated event,
    Emitter<PermissionState> emit,
  ) async {
    final newOrigin = normalizeOrigin(event.url);
    if (_tabDecisions[event.tabId]?.origin != newOrigin) {
      _tabDecisions.remove(event.tabId);
    }
    final stale = state.pending
        .where((p) => p.tabId == event.tabId && p.origin != newOrigin)
        .toList();
    if (stale.isEmpty) return;
    _removeWhere(emit, stale.contains);
    // Usually already cancelled by Chromium; answering a gone request is a
    // no-op on the native side.
    for (final p in stale) {
      await _answer(
        p.request,
        false,
        promptResult: PermissionPromptResult.ignore,
      );
    }
  }

  void _onControllerDisposed(
    PermissionControllerDisposed event,
    Emitter<PermissionState> emit,
  ) {
    _tabDecisions.removeWhere((_, t) => t.controller == event.controller);
    // Closing the browser cancels its requests natively.
    _removeWhere(emit, (p) => p.controller == event.controller);
  }

  void _removeWhere(
    Emitter<PermissionState> emit,
    bool Function(PendingPermission) test,
  ) {
    final remaining = state.pending.where((p) => !test(p)).toList();
    if (remaining.length != state.pending.length) {
      emit(state.copyWith(pending: remaining));
    }
  }
}

/// What the user decided in one tab for the site it is currently on.
class _TabDecisions {
  final WebViewController controller;
  final String origin;
  final Map<SitePermissionKind, bool> decisions = {};

  _TabDecisions({required this.controller, required this.origin});
}
