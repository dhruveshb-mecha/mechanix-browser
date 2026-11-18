import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_logger.dart';
import 'package:mechanix_browser/core/utils/constants.dart';
import 'package:mechanix_browser/core/utils/history_date_grouper.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository.dart';
import 'package:mechanix_browser/features/browser/data/repositories/history_repository_impl.dart';

part 'history_event.dart';
part 'history_state.dart';

/// The history screen: visits newest first, loaded a page at a time
/// ([AppConstants.historyPageSize]), optionally filtered by a search query.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryRepository? repository;

  /// Bumped for every new list (load, search, clear), so a slower request for
  /// an older one can't overwrite it.
  int _generation = 0;

  HistoryBloc({this.repository}) : super(HistoryState.initial()) {
    on<HistoryLoadRequested>(_onLoadRequested);
    on<HistoryLoadMoreRequested>(_onLoadMoreRequested);
    on<HistoryItemDeleted>(_onItemDeleted);
    on<HistoryClearRequested>(_onClearRequested);
    on<HistorySearchQueryChanged>(_onSearchQueryChanged);
  }

  HistoryRepository _ensureRepository() {
    repository ??= HistoryRepositoryImpl();
    return repository!;
  }

  /// One page of the list for [query], after [after] if given.
  Future<List<BrowserHistory>> _page(String query, BrowserHistory? after) {
    final repo = _ensureRepository();
    const limit = AppConstants.historyPageSize;
    return query.isEmpty
        ? repo.getHistory(limit: limit, after: after)
        : repo.searchHistory(query, limit: limit, after: after);
  }

  /// Replaces the list with the first page for [query].
  Future<void> _loadFirstPage(String query, Emitter<HistoryState> emit) async {
    final generation = ++_generation;
    try {
      final items = await _page(query, null);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          searchQuery: query,
          historyItems: items,
          groupedSections: HistoryDateGrouper.groupHistory(items),
          hasMore: items.length == AppConstants.historyPageSize,
          isLoading: false,
          isLoadingMore: false,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error loading history', error: e, stack: stackTrace);
      if (generation == _generation) {
        emit(state.copyWith(isLoading: false, isLoadingMore: false));
      }
    }
  }

  Future<void> _onLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    // Opening the screen starts from the unfiltered list.
    emit(state.copyWith(isLoading: true, searchQuery: ''));
    await _loadFirstPage('', emit);
  }

  Future<void> _onSearchQueryChanged(
    HistorySearchQueryChanged event,
    Emitter<HistoryState> emit,
  ) => _loadFirstPage(event.query.trim(), emit);

  /// Appends the next page, if there is one and none is loading.
  Future<void> _onLoadMoreRequested(
    HistoryLoadMoreRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isEmpty) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final more = await _page(state.searchQuery, state.historyItems.last);
      if (generation != _generation) return;
      final items = [...state.historyItems, ...more];
      emit(
        state.copyWith(
          historyItems: items,
          groupedSections: HistoryDateGrouper.groupHistory(items),
          hasMore: more.length == AppConstants.historyPageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error loading more history', error: e, stack: stackTrace);
      if (generation == _generation) emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onItemDeleted(
    HistoryItemDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final repo = _ensureRepository();
    await repo.deleteVisit(event.item.id);

    final remainingItems = state.historyItems
        .where((item) => item.id != event.item.id)
        .toList();

    emit(
      state.copyWith(
        historyItems: remainingItems,
        groupedSections: HistoryDateGrouper.groupHistory(remainingItems),
      ),
    );
  }

  Future<void> _onClearRequested(
    HistoryClearRequested event,
    Emitter<HistoryState> emit,
  ) async {
    _generation++;
    final repo = _ensureRepository();
    await repo.clearHistory();
    emit(
      state.copyWith(
        historyItems: const [],
        groupedSections: const [],
        hasMore: false,
        isLoadingMore: false,
      ),
    );
  }
}
