import 'package:equatable/equatable.dart';
import 'package:webview_cef/webview_cef.dart';

class BrowserTab extends Equatable {
  final String id;
  final WebViewController controller;
  final String currentUrl;
  final String title;
  final bool isHomePage;

  final bool isPrivate;

  const BrowserTab({
    required this.id,
    required this.controller,
    required this.currentUrl,
    required this.title,
    required this.isHomePage,
    this.isPrivate = false,
  });

  BrowserTab copyWith({
    String? id,
    WebViewController? controller,
    String? currentUrl,
    String? title,
    bool? isHomePage,
    bool? isPrivate,
  }) {
    return BrowserTab(
      id: id ?? this.id,
      controller: controller ?? this.controller,
      currentUrl: currentUrl ?? this.currentUrl,
      title: title ?? this.title,
      isHomePage: isHomePage ?? this.isHomePage,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  @override
  List<Object?> get props => [id, controller, currentUrl, title, isHomePage, isPrivate];
}
