part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoadRequested extends HistoryEvent {
  const HistoryLoadRequested();
}

class HistoryItemDeleted extends HistoryEvent {
  final BrowserHistory item;
  const HistoryItemDeleted(this.item);

  @override
  List<Object?> get props => [item];
}

class HistoryClearRequested extends HistoryEvent {
  const HistoryClearRequested();
}

class HistorySearchQueryChanged extends HistoryEvent {
  final String query;
  const HistorySearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
