import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/report_entity.dart';
import 'report_controller.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.type});

  final ReportType type;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _searchController = TextEditingController();
  final _statusController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportControllerProvider);
    return AppScaffold(
      title: widget.type.label,
      child: RefreshIndicator(
        onRefresh: _load,
        child: AppScreenListView(
          children: [
            _Filters(
              searchController: _searchController,
              statusController: _statusController,
              onSearchChanged: _onSearchChanged,
              onStatusSubmitted: _onStatusSubmitted,
            ),
            const SizedBox(height: 12),
            _ExportActions(
              isExporting: state.isExporting,
              progress: state.exportProgress,
              onExport: _export,
            ),
            const SizedBox(height: 12),
            if (state.summary.isNotEmpty)
              _Summary(summary: state.summary, total: state.total),
            if (state.summary.isNotEmpty) const SizedBox(height: 12),
            if (state.isLoading && state.items.isEmpty)
              const AppSectionCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (state.errorMessage != null)
              AppEmptyCard(message: state.errorMessage!)
            else if (state.items.isEmpty)
              const AppEmptyCard(message: 'No report rows found.')
            else
              for (final row in state.items) _ReportRow(row: row),
          ],
        ),
      ),
    );
  }

  Future<void> _load() {
    return ref.read(reportControllerProvider.notifier).load(widget.type);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final current = ref.read(reportControllerProvider).filters;
      final trimmed = value.trim();
      ref
          .read(reportControllerProvider.notifier)
          .load(
            widget.type,
            current.copyWith(
              search: trimmed.length >= 2 ? trimmed : null,
              clearSearch: trimmed.isEmpty || trimmed.length < 2,
              page: 1,
            ),
          );
    });
  }

  void _onStatusSubmitted(String value) {
    final current = ref.read(reportControllerProvider).filters;
    final trimmed = value.trim();
    ref
        .read(reportControllerProvider.notifier)
        .load(
          widget.type,
          current.copyWith(
            status: trimmed.isEmpty ? null : trimmed,
            clearStatus: trimmed.isEmpty,
            page: 1,
          ),
        );
  }

  Future<void> _export(String format) async {
    final path = await ref
        .read(reportControllerProvider.notifier)
        .export(widget.type, format);
    if (!mounted || path == null) return;
    await SharePlus.instance.share(
      ShareParams(title: '${widget.type.label} report', files: [XFile(path)]),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.searchController,
    required this.statusController,
    required this.onSearchChanged,
    required this.onStatusSubmitted,
  });

  final TextEditingController searchController;
  final TextEditingController statusController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        children: [
          TextField(
            key: const Key('reportSearchField'),
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(AppIcons.search),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reportStatusField'),
            controller: statusController,
            decoration: const InputDecoration(labelText: 'Status'),
            textInputAction: TextInputAction.search,
            onSubmitted: onStatusSubmitted,
          ),
        ],
      ),
    );
  }
}

class _ExportActions extends StatelessWidget {
  const _ExportActions({
    required this.isExporting,
    required this.progress,
    required this.onExport,
  });

  final bool isExporting;
  final double? progress;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final format in const ['csv', 'xlsx', 'pdf'])
                OutlinedButton.icon(
                  key: Key('exportReport${format.toUpperCase()}Button'),
                  onPressed: isExporting ? null : () => onExport(format),
                  icon: const Icon(AppIcons.download),
                  label: Text(format.toUpperCase()),
                ),
            ],
          ),
          if (isExporting) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.total});

  final Map<String, dynamic> summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final entries = {'totalRecords': total, ...summary}.entries.take(6);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final entry in entries)
          SizedBox(
            width: 160,
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.value}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final entries = row.entries.toList();
    final title = entries.isEmpty ? 'Report row' : '${entries.first.value}';
    final subtitle = entries
        .skip(1)
        .take(4)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 10),
      leading: const Icon(AppIcons.file),
      title: Text(title),
      subtitle: Text(subtitle.isEmpty ? 'No details' : subtitle),
    );
  }
}
