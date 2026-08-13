import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SingleInstanceService {
  static const int _port = 12345; // You might want to choose a more unique port
  static ServerSocket? _serverSocket;
  static final StreamController<String> _urlController = StreamController<String>.broadcast();

  Stream<String> get urlStream => _urlController.stream;

  Future<bool> checkAndHandleSingleInstance(List<String> args) async {
    String? url;
    // Simple argument parsing: find the first argument that doesn't start with '-'
    // or follows the expected pattern.
    // The Exec line is: /home/mecha/ojas-browser/mechanix_browser -b . -s 1 %U
    for (int i = 0; i < args.length; i++) {
      if (!args[i].startsWith('-') && i > 0 && args[i-1] != '-b' && args[i-1] != '-s') {
        url = args[i];
        break;
      }
    }
    
    // If no URL found by heuristic, just take the last if it doesn't look like a flag
    if (url == null && args.isNotEmpty && !args.last.startsWith('-')) {
        url = args.last;
    }

    try {
      // Try to bind to the port. If it fails, an instance is likely already running.
      _serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _serverSocket!.listen(_handleConnection);
      return true; // We are the first instance
    } catch (e) {
      // Could not bind, instance already running.
      if (url != null) {
        await _sendUrlToExistingInstance(url);
      }
      return false; // We should exit
    }
  }

  void _handleConnection(Socket socket) {
    socket.listen((data) {
      final message = String.fromCharCodes(data).trim();
      if (message.isNotEmpty) {
        _urlController.add(message);
      }
    }, onDone: () => socket.destroy());
  }

  Future<void> _sendUrlToExistingInstance(String url) async {
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, _port);
      socket.write(url);
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint('Error sending URL to existing instance: $e');
    }
  }

  void dispose() {
    _serverSocket?.close();
    _urlController.close();
  }
}
