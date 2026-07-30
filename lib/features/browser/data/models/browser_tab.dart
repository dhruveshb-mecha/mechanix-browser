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
  final String? imagePath;

  const BrowserTab({
    required this.id,
    required this.controller,
    required this.currentUrl,
    required this.title,
    required this.isHomePage,
    required this.isLoading,
    this.isPrivate = false,
    this.imagePath,
  });

  BrowserTab copyWith({
    String? id,
    WebViewController? controller,
    String? currentUrl,
    String? title,
    bool? isHomePage,
    bool? isLoading,
    bool? isPrivate,
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
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
    imagePath,
  ];
}
