import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:webview_cef/webview_cef.dart';

class BrowserTab extends Equatable {
  final String id;
  final WebViewController controller;
  final String currentUrl;
  final String title;
  final bool isHomePage;
  final bool isLoading;
  final bool isPrivate;
  final Uint8List? screenshot;

  const BrowserTab({
    required this.id,
    required this.controller,
    required this.currentUrl,
    required this.title,
    required this.isHomePage,
    required this.isLoading,
    this.isPrivate = false,
    this.screenshot,
  });

  BrowserTab copyWith({
    String? id,
    WebViewController? controller,
    String? currentUrl,
    String? title,
    bool? isHomePage,
    bool? isLoading,
    bool? isPrivate,
    Uint8List? screenshot,
    int? screenshotVersion,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      controller: controller ?? this.controller,
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      isHomePage: isHomePage ?? this.isHomePage,
      isLoading: isLoading ?? this.isLoading,
      isPrivate: isPrivate ?? this.isPrivate,
      screenshot: screenshot ?? this.screenshot,
    );
  }

  @override
  List<Object?> get props => [
    id,
    controller,
    currentUrl,
    title,
    isHomePage,
    isLoading,
    isPrivate,
    screenshot,
  ];
}
