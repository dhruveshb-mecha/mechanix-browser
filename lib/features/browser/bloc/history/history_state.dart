part of 'history_bloc.dart';

class HistoryState extends Equatable {
  final List<BrowserHistory> historyItems;
  final List<HistoryGroup> groupedSections;
  final String searchQuery;
  final bool isLoading;

  const HistoryState({
    required this.historyItems,
    required this.groupedSections,
    required this.searchQuery,
    required this.isLoading,
  });

  factory HistoryState.initial() {
    return const HistoryState(
      historyItems: [],
      groupedSections: [],
      searchQuery: '',
      isLoading: false,
    );
  }

  bool get isEmpty => historyItems.isEmpty;

  HistoryState copyWith({
    List<BrowserHistory>? historyItems,
    List<HistoryGroup>? groupedSections,
    String? searchQuery,
    bool? isLoading,
  }) {
    return HistoryState(
      historyItems: historyItems ?? this.historyItems,
      groupedSections: groupedSections ?? this.groupedSections,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    historyItems,
    groupedSections,
    searchQuery,
    isLoading,
  ];
}
