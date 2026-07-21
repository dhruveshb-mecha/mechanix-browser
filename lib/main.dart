import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mechanix Browser',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyWebView(),
    );
  }
}

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView(
      loading: const Center(child: CircularProgressIndicator()),
    );
    _init();
  }

  Future<void> _init() async {
    await WebviewManager().initialize(); // call once for the whole app
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: (url) => debugPrint('url => $url'),
      onLoadEnd: (controller, url) => debugPrint('loaded => $url'),
    ));
    await _controller.initialize('https://flutter.dev');
  }

  @override
  void dispose() {
    _controller.dispose();
    WebviewManager().quit(); // only when tearing down the whole app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanix Browser'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller,
        builder: (_, ready, __) =>
            ready ? _controller.webviewWidget : _controller.loadingWidget,
      ),
    );
  }
}
