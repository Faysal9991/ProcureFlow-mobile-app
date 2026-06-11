import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/status_chip.dart';

const procurementAssistantCatalogId = 'com.procurement_management.assistant.v1';

Catalog procurementAssistantCatalog() {
  return BasicCatalogItems.asNoAssetCatalog(
    systemPromptFragments: const [
      'Use procurement widgets for guidance, summaries, draft previews, '
          'report filters, RFQ insights, and offline sync state only.',
      'Do not approve, submit, pay, delete, or otherwise mutate records. '
          'Use navigation actions so the app can route to deterministic '
          'screens with existing permission checks and confirmations.',
    ],
  ).copyWith(
    catalogId: procurementAssistantCatalogId,
    newItems: [
      _assistantMessageCard,
      _assistantSummaryCards,
      _assistantActionList,
      _assistantDraftPreview,
      _assistantReportFilterPreview,
      _assistantRfqInsight,
      _assistantSyncStatus,
    ],
  );
}

final _assistantMessageCard = CatalogItem(
  name: 'AssistantMessageCard',
  dataSchema: S.object(
    description: 'A short assistant message in a procurement card.',
    properties: {'title': S.string(), 'message': S.string()},
    required: ['title', 'message'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    return AppSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(AppIcons.assistant, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _string(data, 'title'),
                  style: Theme.of(
                    itemContext.buildContext,
                  ).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(_string(data, 'message')),
              ],
            ),
          ),
        ],
      ),
    );
  },
);

final _assistantSummaryCards = CatalogItem(
  name: 'AssistantSummaryCards',
  dataSchema: S.object(
    description: 'A compact grid of permission-aware procurement metrics.',
    properties: {
      'cards': S.list(
        items: S.object(
          properties: {
            'label': S.string(),
            'value': S.string(),
            'icon': S.string(),
          },
          required: ['label', 'value'],
        ),
      ),
    },
    required: ['cards'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final cards = _maps(data['cards']);
    if (cards.isEmpty) {
      return const AppEmptyCard(message: 'No assistant summary available.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth > 720 ? 3 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: tileWidth,
                height: 132,
                child: AppSummaryCard(
                  icon: _iconFor(
                    _string(card, 'icon', fallback: _string(card, 'label')),
                  ),
                  label: _string(card, 'label'),
                  value: _string(card, 'value'),
                ),
              ),
          ],
        );
      },
    );
  },
);

final _assistantActionList = CatalogItem(
  name: 'AssistantActionList',
  dataSchema: S.object(
    description: 'A list of safe navigation actions.',
    properties: {
      'title': S.string(),
      'actions': S.list(
        items: S.object(
          properties: {
            'title': S.string(),
            'subtitle': S.string(),
            'route': S.string(),
            'icon': S.string(),
            'enabled': S.boolean(),
          },
          required: ['title', 'subtitle', 'route'],
        ),
      ),
    },
    required: ['actions'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final actions = _maps(data['actions']);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _string(data, 'title', fallback: 'Suggested next steps'),
          style: Theme.of(itemContext.buildContext).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final action in actions)
          AppListTileCard(
            margin: const EdgeInsets.only(bottom: 10),
            leading: Icon(
              _iconFor(
                _string(action, 'icon', fallback: _string(action, 'title')),
              ),
            ),
            title: Text(_string(action, 'title')),
            subtitle: Text(_string(action, 'subtitle')),
            trailing: Icon(
              _bool(action, 'enabled', fallback: true)
                  ? AppIcons.chevronRight
                  : AppIcons.lock,
            ),
            onTap: _bool(action, 'enabled', fallback: true)
                ? () => _dispatchRoute(itemContext, _string(action, 'route'))
                : null,
          ),
      ],
    );
  },
);

final _assistantDraftPreview = CatalogItem(
  name: 'AssistantDraftPreview',
  dataSchema: S.object(
    description: 'A non-mutating preview for a purchase request draft.',
    properties: {
      'title': S.string(),
      'priority': S.string(),
      'neededBy': S.string(),
      'route': S.string(),
      'items': S.list(
        items: S.object(
          properties: {
            'name': S.string(),
            'quantity': S.string(),
            'unit': S.string(),
          },
          required: ['name', 'quantity'],
        ),
      ),
    },
    required: ['title', 'priority', 'items'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final items = _maps(data['items']);
    final route = _string(data, 'route', fallback: '/requests/new');

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _string(data, 'title'),
                  style: Theme.of(
                    itemContext.buildContext,
                  ).textTheme.titleMedium,
                ),
              ),
              StatusChip(status: _string(data, 'priority')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Needed by: ${_string(data, 'neededBy', fallback: 'Choose in form')}',
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(AppIcons.item, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_string(item, 'name'))),
                  Text(
                    '${_string(item, 'quantity')} '
                    '${_string(item, 'unit', fallback: 'pcs')}',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('assistantOpenRequestDraftButton'),
            onPressed: () => _dispatchRoute(itemContext, route),
            icon: const Icon(AppIcons.arrowForward),
            label: const Text('Open request form'),
          ),
        ],
      ),
    );
  },
);

final _assistantReportFilterPreview = CatalogItem(
  name: 'AssistantReportFilterPreview',
  dataSchema: S.object(
    description: 'A non-mutating report filter preview.',
    properties: {
      'title': S.string(),
      'route': S.string(),
      'filters': S.list(
        items: S.object(
          properties: {'label': S.string(), 'value': S.string()},
          required: ['label', 'value'],
        ),
      ),
    },
    required: ['title', 'route', 'filters'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final filters = _maps(data['filters']);

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _string(data, 'title'),
            style: Theme.of(itemContext.buildContext).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          AppInfoGrid(
            items: [
              for (final filter in filters)
                AppInfoItem(
                  label: _string(filter, 'label'),
                  value: _string(filter, 'value'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('assistantOpenReportButton'),
            onPressed: () =>
                _dispatchRoute(itemContext, _string(data, 'route')),
            icon: const Icon(AppIcons.search),
            label: const Text('Open report'),
          ),
        ],
      ),
    );
  },
);

final _assistantRfqInsight = CatalogItem(
  name: 'AssistantRfqInsight',
  dataSchema: S.object(
    description: 'RFQ comparison guidance without selecting a winner.',
    properties: {
      'title': S.string(),
      'route': S.string(),
      'bullets': S.list(items: S.string()),
    },
    required: ['title', 'route', 'bullets'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;
    final bullets = _strings(data['bullets']);

    return AppSectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _string(data, 'title'),
            style: Theme.of(itemContext.buildContext).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.circleCheck, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(bullet)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('assistantOpenRfqButton'),
            onPressed: () =>
                _dispatchRoute(itemContext, _string(data, 'route')),
            icon: const Icon(AppIcons.compare),
            label: const Text('Open RFQs'),
          ),
        ],
      ),
    );
  },
);

final _assistantSyncStatus = CatalogItem(
  name: 'AssistantSyncStatus',
  dataSchema: S.object(
    description: 'A safe offline sync status summary.',
    properties: {
      'title': S.string(),
      'message': S.string(),
      'pendingCount': S.integer(),
      'route': S.string(),
    },
    required: ['title', 'message', 'pendingCount', 'route'],
  ),
  widgetBuilder: (itemContext) {
    final data = itemContext.data as JsonMap;

    return AppSectionCard(
      onTap: () => _dispatchRoute(itemContext, _string(data, 'route')),
      child: Row(
        children: [
          const Icon(AppIcons.sync, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _string(data, 'title'),
                  style: Theme.of(
                    itemContext.buildContext,
                  ).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(_string(data, 'message')),
              ],
            ),
          ),
          StatusChip(status: '${_int(data, 'pendingCount')} pending'),
        ],
      ),
    );
  },
);

void _dispatchRoute(CatalogItemContext itemContext, String route) {
  itemContext.dispatchEvent(
    UserActionEvent(
      name: 'assistant.navigate',
      sourceComponentId: itemContext.id,
      context: {'route': route},
    ),
  );
}

String _string(JsonMap data, String key, {String fallback = ''}) {
  final value = data[key];
  if (value == null) return fallback;
  return value.toString();
}

bool _bool(JsonMap data, String key, {required bool fallback}) {
  final value = data[key];
  return value is bool ? value : fallback;
}

int _int(JsonMap data, String key) {
  final value = data[key];
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<JsonMap> _maps(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) item.toString()];
}

IconData _iconFor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('approval')) return AppIcons.approval;
  if (normalized.contains('request')) return AppIcons.description;
  if (normalized.contains('vendor')) return AppIcons.vendors;
  if (normalized.contains('rfq') || normalized.contains('quote')) {
    return AppIcons.compare;
  }
  if (normalized.contains('order') || normalized.contains('po')) {
    return AppIcons.order;
  }
  if (normalized.contains('invoice') ||
      normalized.contains('payment') ||
      normalized.contains('budget') ||
      normalized.contains('spend')) {
    return AppIcons.money;
  }
  if (normalized.contains('report')) return AppIcons.history;
  if (normalized.contains('sync') || normalized.contains('offline')) {
    return AppIcons.sync;
  }
  if (normalized.contains('notification')) return AppIcons.bellActive;
  return AppIcons.list;
}
