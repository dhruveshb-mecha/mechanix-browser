import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/history_date_grouper.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryRepository? repository;

  HistoryBloc({this.repository}) : super(HistoryState.initial()) {
    on<HistoryLoadRequested>(_onLoadRequested);
    on<HistoryItemDeleted>(_onItemDeleted);
    on<HistoryClearRequested>(_onClearRequested);
    on<HistorySearchQueryChanged>(_onSearchQueryChanged);
  }

  HistoryRepository _ensureRepository() {
    repository ??= HistoryRepositoryImpl();
    return repository!;
  }

  Future<void> _onLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final repo = _ensureRepository();
      final items = repo.getHistory();
      final grouped = HistoryDateGrouper.groupHistory(items);
      emit(
        state.copyWith(
          historyItems: items,
          groupedSections: grouped,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onItemDeleted(
    HistoryItemDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final repo = _ensureRepository();
    repo.deleteHistory(event.item.id);

    final remainingItems = state.historyItems
        .where((item) => item.id != event.item.id)
        .toList();

    final grouped = HistoryDateGrouper.groupHistory(remainingItems);

    emit(
      state.copyWith(historyItems: remainingItems, groupedSections: grouped),
    );
  }

  Future<void> _onClearRequested(
    HistoryClearRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final repo = _ensureRepository();
    repo.clearHistory();
    emit(state.copyWith(historyItems: const [], groupedSections: const []));
  }

  Future<void> _onSearchQueryChanged(
    HistorySearchQueryChanged event,
    Emitter<HistoryState> emit,
  ) async {
    final repo = _ensureRepository();
    final query = event.query.trim();
    final List<BrowserHistory> results;
    if (query.isEmpty) {
      results = repo.getHistory();
    } else {
      results = repo.searchHistory(query);
    }

    final grouped = HistoryDateGrouper.groupHistory(results);
    emit(
      state.copyWith(
        searchQuery: query,
        historyItems: results,
        groupedSections: grouped,
      ),
    );
  }

  @override
  Future<void> close() async {
    repository?.close();
    return super.close();
  }
}
