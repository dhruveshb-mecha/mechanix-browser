import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';
import 'package:mechanix_browser/features/browser/bloc/browser_bloc.dart';
import 'package:mechanix_browser/features/browser/bloc/history/history_bloc.dart';
import 'package:mechanix_browser/features/browser/data/models/browser_history.dart';
import 'package:mechanix_browser/features/browser/presentation/widgets/history/history_section.dart';
import 'package:mechanix_browser/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryLoadRequested());
  }

  void _onItemTap(BuildContext context, BrowserHistory item) {
    if (item.url.isNotEmpty) {
      context.read<BrowserBloc>().add(BrowserUrlLoadRequested(item.url));
      Navigator.pop(context);
    }
  }

  void _onItemDelete(BuildContext context, BrowserHistory item) {
    context.read<HistoryBloc>().add(HistoryItemDeleted(item));
  }

  void _onClearAll(BuildContext context) {
    context.read<HistoryBloc>().add(const HistoryClearRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        final hasItems = !state.isEmpty;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(l10n.history),
            actions: [
              if (hasItems)
                TextButton(
                  onPressed: () => _onClearAll(context),
                  child: Text(
                    l10n.clearAll,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.isEmpty
              // ? const HistoryEmptyState()
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.panelBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.history,
                          color: colors.textSecondary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.comingSoon(l10n.history),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.workingHard, style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: state.groupedSections.length,
                  itemBuilder: (context, index) {
                    final group = state.groupedSections[index];
                    return HistorySection(
                      group: group,
                      onItemTap: (item) => _onItemTap(context, item),
                      onItemDelete: (item) => _onItemDelete(context, item),
                    );
                  },
                ),
        );
      },
    );
  }
}
