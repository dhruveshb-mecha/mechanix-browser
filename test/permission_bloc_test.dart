import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_browser/features/browser/bloc/permission/permission_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/permission/site_permission_kind.dart';
import 'package:webview_cef/webview_cef.dart';

class Answer {
  final WebviewPermissionRequest request;
  final bool allow;
  final PermissionPromptResult? promptResult;
  Answer(this.request, this.allow, this.promptResult);
}

WebviewPermissionRequest media(
  int id,
  int mask, [
  String origin = 'https://meet.example.com/',
]) => WebviewPermissionRequest(
  requestId: id,
  isMedia: true,
  origin: origin,
  permissions: mask,
);

WebviewPermissionRequest prompt(
  int id,
  int mask, [
  String origin = 'https://maps.example.com/',
]) => WebviewPermissionRequest(
  requestId: id,
  isMedia: false,
  origin: origin,
  permissions: mask,
);

const camMic =
    MediaPermission.deviceVideoCapture | MediaPermission.deviceAudioCapture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Answer> answers;

  /// Decisions in Chromium's normal profile: origin -> permission -> value.
  late Map<String, Map<StoredPermission, StoredPermissionValue>> chromium;
  late List<(String, StoredPermission)> chromiumReads;
  late PermissionBloc bloc;
  late WebViewController tabA;
  late WebViewController tabB;

  setUp(() {
    answers = [];
    chromium = {};
    chromiumReads = [];
    bloc = PermissionBloc(
      respond: (request, allow, {promptResult}) async {
        answers.add(Answer(request, allow, promptResult));
      },
      readChromium: (origin, permission) async {
        chromiumReads.add((origin, permission));
        return chromium[origin]?[permission];
      },
    );
    const channel = MethodChannel('test');
    tabA = WebViewController(channel, 1);
    tabB = WebViewController(channel, 2);
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void request(
    WebViewController c,
    String tabId,
    WebviewPermissionRequest r, {
    bool isPrivate = false,
  }) {
    bloc.add(
      PermissionRequested(
        tabId: tabId,
        controller: c,
        request: r,
        isPrivate: isPrivate,
      ),
    );
  }

  Future<void> decide(String tabId, {required bool allow}) async {
    bloc.add(PermissionDecided(bloc.state.promptFor(tabId)!, allow: allow));
    await settle();
  }

  group('classifyPermissionRequest', () {
    test('maps media bits to camera and microphone', () {
      final c = classifyPermissionRequest(media(1, camMic));
      expect(c.kinds, [
        SitePermissionKind.camera,
        SitePermissionKind.microphone,
      ]);
      expect(c.hasUnsupported, isFalse);
    });

    test('maps the notifications bit', () {
      final c = classifyPermissionRequest(
        prompt(1, PromptPermission.notifications),
      );
      expect(c.kinds, [SitePermissionKind.notifications]);
      expect(c.hasUnsupported, isFalse);
    });

    test('screen capture and sensors are unsupported', () {
      expect(
        classifyPermissionRequest(
          media(1, MediaPermission.desktopVideoCapture),
        ).hasUnsupported,
        isTrue,
      );
      expect(
        classifyPermissionRequest(
          prompt(1, PromptPermission.sensors),
        ).hasUnsupported,
        isTrue,
      );
    });

    test('normalizeOrigin strips path and trailing slash', () {
      expect(normalizeOrigin('https://a.com/'), 'https://a.com');
      expect(normalizeOrigin('https://a.com:8443/x?y'), 'https://a.com:8443');
    });
  });

  test('unknown site is queued for a prompt, nothing answered yet', () async {
    request(tabA, 'a', media(1, camMic));
    await settle();
    expect(bloc.state.promptFor('a')?.kinds, [
      SitePermissionKind.camera,
      SitePermissionKind.microphone,
    ]);
    expect(bloc.state.promptFor('b'), isNull);
    expect(answers, isEmpty);
  });

  test('unsupported request is denied without prompting', () async {
    request(tabA, 'a', prompt(7, PromptPermission.sensors));
    await settle();
    expect(bloc.state.pending, isEmpty);
    expect(answers.single.allow, isFalse);
  });

  test('notification Allow is answered; Chromium does the storing', () async {
    request(tabA, 'a', prompt(8, PromptPermission.notifications));
    await settle();
    expect(bloc.state.promptFor('a')!.kinds, [
      SitePermissionKind.notifications,
    ]);
    await decide('a', allow: true);
    expect(answers.single.allow, isTrue);
    expect(chromiumReads, isEmpty, reason: 'normal tabs never read');
  });

  group('camera and microphone last for the visit', () {
    test('asked once while the tab stays on the site', () async {
      request(tabA, 'a', media(1, camMic));
      await settle();
      await decide('a', allow: true);

      request(tabA, 'a', media(2, MediaPermission.deviceVideoCapture));
      await settle();
      expect(bloc.state.pending, isEmpty);
      expect(answers.map((a) => (a.request.requestId, a.allow)), [
        (1, true),
        (2, true),
      ]);
    });

    test('a block in the visit wins over an undecided kind', () async {
      request(tabA, 'a', media(1, MediaPermission.deviceAudioCapture));
      await settle();
      await decide('a', allow: false);

      request(tabA, 'a', media(2, camMic));
      await settle();
      expect(bloc.state.pending, isEmpty);
      expect(answers.last.allow, isFalse);
    });

    test('a new visit asks again', () async {
      request(tabA, 'a', media(1, camMic));
      await settle();
      await decide('a', allow: true);

      bloc.add(const PermissionTabNavigated(tabId: 'a', url: 'https://x.org'));
      bloc.add(
        const PermissionTabNavigated(
          tabId: 'a',
          url: 'https://meet.example.com/room',
        ),
      );
      request(tabA, 'a', media(2, camMic));
      await settle();
      expect(bloc.state.promptFor('a')?.request.requestId, 2);
    });

    test('same-site navigation keeps the decision', () async {
      request(tabA, 'a', media(1, camMic));
      await settle();
      await decide('a', allow: true);

      bloc.add(
        const PermissionTabNavigated(
          tabId: 'a',
          url: 'https://meet.example.com/room/2',
        ),
      );
      request(tabA, 'a', media(2, camMic));
      await settle();
      expect(bloc.state.pending, isEmpty);
      expect(answers.last.allow, isTrue);
    });

    test('closing the tab forgets the decision', () async {
      request(tabA, 'a', media(1, camMic));
      await settle();
      await decide('a', allow: true);

      bloc.add(PermissionControllerDisposed(tabA));
      request(tabB, 'a', media(2, camMic));
      await settle();
      expect(bloc.state.promptFor('a')?.request.requestId, 2);
    });

    test('another tab on the same site is asked itself', () async {
      request(tabA, 'a', media(1, camMic));
      request(tabB, 'b', media(2, camMic));
      await settle();
      await decide('a', allow: true);

      expect(answers.single.request.requestId, 1);
      expect(bloc.state.promptFor('b')?.request.requestId, 2);
    });
  });

  test('prompt permission settles the same site in other normal tabs', () async {
    request(tabA, 'a', prompt(1, PromptPermission.geolocation));
    request(tabB, 'b', prompt(2, PromptPermission.geolocation));
    await settle();
    await decide('a', allow: false);

    expect(bloc.state.pending, isEmpty);
    expect(answers.map((a) => (a.request.requestId, a.allow)), [
      (1, false),
      (2, false),
    ]);
  });

  test('closing the prompt denies once and remembers nothing', () async {
    request(tabA, 'a', media(5, camMic));
    await settle();
    bloc.add(PermissionPromptClosed(bloc.state.promptFor('a')!));
    await settle();
    expect(answers.single.allow, isFalse);
    expect(answers.single.promptResult, PermissionPromptResult.dismiss);

    request(tabA, 'a', media(6, camMic));
    await settle();
    expect(bloc.state.promptFor('a')?.request.requestId, 6);
  });

  test('navigating to another origin drops the request', () async {
    request(tabA, 'a', media(1, camMic));
    await settle();
    bloc.add(
      const PermissionTabNavigated(
        tabId: 'a',
        url: 'https://meet.example.com/room/2',
      ),
    );
    await settle();
    expect(bloc.state.pending, hasLength(1), reason: 'same origin keeps it');

    bloc.add(
      const PermissionTabNavigated(tabId: 'a', url: 'https://other.org/'),
    );
    await settle();
    expect(bloc.state.pending, isEmpty);
  });

  test('native dismissal and disposed tabs remove pending requests', () async {
    request(tabA, 'a', prompt(9, PromptPermission.geolocation));
    request(tabB, 'b', media(9, camMic));
    await settle();
    bloc.add(
      PermissionDismissed(controller: tabA, requestId: 9, isMedia: false),
    );
    await settle();
    expect(bloc.state.pending.single.tabId, 'b');
    bloc.add(PermissionControllerDisposed(tabB));
    await settle();
    expect(bloc.state.pending, isEmpty);
    expect(answers, isEmpty);
  });

  group('private tabs', () {
    test('inherit a block from the normal profile', () async {
      chromium['https://maps.example.com'] = {
        StoredPermission.geolocation: StoredPermissionValue.block,
      };
      request(
        tabA,
        'a',
        prompt(1, PromptPermission.geolocation),
        isPrivate: true,
      );
      await settle();
      expect(bloc.state.pending, isEmpty);
      expect(answers.single.allow, isFalse);
      expect(chromiumReads.single, (
        'https://maps.example.com',
        StoredPermission.geolocation,
      ));
    });

    test('never inherit an allow', () async {
      chromium['https://maps.example.com'] = {
        StoredPermission.notifications: StoredPermissionValue.allow,
      };
      request(
        tabA,
        'a',
        prompt(1, PromptPermission.notifications),
        isPrivate: true,
      );
      await settle();
      expect(bloc.state.promptFor('a')?.request.requestId, 1);
      expect(answers, isEmpty);
    });

    test('camera has nothing to inherit and is prompted', () async {
      request(tabA, 'a', media(1, camMic), isPrivate: true);
      await settle();
      expect(chromiumReads, isEmpty);
      expect(bloc.state.promptFor('a')?.request.requestId, 1);
    });

    test('private decisions do not settle normal tabs', () async {
      request(
        tabA,
        'a',
        prompt(1, PromptPermission.geolocation),
        isPrivate: true,
      );
      request(tabB, 'b', prompt(2, PromptPermission.geolocation));
      await settle();
      await decide('a', allow: true);

      expect(answers.single.request.requestId, 1);
      expect(bloc.state.promptFor('b')?.request.requestId, 2);
    });
  });
}
