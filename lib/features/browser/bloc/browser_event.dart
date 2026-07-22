part of 'browser_bloc.dart';

sealed class BrowserEvent extends Equatable {
  const BrowserEvent();

  @override
  List<Object?> get props => [];
}

class BrowserInitialized extends BrowserEvent {}

class BrowserUrlLoadRequested extends BrowserEvent {
  final String url;
  const BrowserUrlLoadRequested(this.url);

  @override
  List<Object?> get props => [url];
}

class BrowserGoBackRequested extends BrowserEvent {}

class BrowserGoForwardRequested extends BrowserEvent {}

class BrowserReloadRequested extends BrowserEvent {}

class BrowserDevToolsRequested extends BrowserEvent {}

class BrowserGoHomeRequested extends BrowserEvent {}

class BrowserUrlChanged extends BrowserEvent {
  final String tabId;
  final String url;
  const BrowserUrlChanged({required this.tabId, required this.url});

  @override
  List<Object?> get props => [tabId, url];
}

class BrowserTitleChanged extends BrowserEvent {
  final String tabId;
  final String title;
  const BrowserTitleChanged({required this.tabId, required this.title});

  @override
  List<Object?> get props => [tabId, title];
}

class BrowserNewTabRequested extends BrowserEvent {
  final String? initialUrl;
  const BrowserNewTabRequested({this.initialUrl});

  @override
  List<Object?> get props => [initialUrl];
}

class BrowserCloseTabRequested extends BrowserEvent {
  final int index;
  const BrowserCloseTabRequested(this.index);

  @override
  List<Object?> get props => [index];
}

class BrowserSwitchTabRequested extends BrowserEvent {
  final int index;
  const BrowserSwitchTabRequested(this.index);

  @override
  List<Object?> get props => [index];
}

class BrowserCloseAllTabsRequested extends BrowserEvent {
  const BrowserCloseAllTabsRequested();
}

class BrowserHistoryClearRequested extends BrowserEvent {}

class BrowserSearchQueryChanged extends BrowserEvent {
  final String query;
  const BrowserSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class BrowserHistoryItemDeleted extends BrowserEvent {
  final BrowserHistory item;
  final String currentQuery;
  const BrowserHistoryItemDeleted(this.item, this.currentQuery);

  @override
  List<Object?> get props => [item, currentQuery];
}

class BrowserBookmarkAdded extends BrowserEvent {
  final String url;
  final String? label;
  final BookmarkType type;

  const BrowserBookmarkAdded({
    required this.url,
    required this.label,
    required this.type,
  });

  @override
  List<Object?> get props => [url, label, type];
}

class BrowserBookmarkRemoved extends BrowserEvent {
  final int id;
  final BookmarkType type;

  const BrowserBookmarkRemoved({
    required this.id,
    required this.type,
  });

  @override
  List<Object?> get props => [id, type];
}

class BrowserBookmarkToggled extends BrowserEvent {
  final String url;
  final String? title;

  const BrowserBookmarkToggled({
    required this.url,
    this.title,
  });

  @override
  List<Object?> get props => [url, title];
}
