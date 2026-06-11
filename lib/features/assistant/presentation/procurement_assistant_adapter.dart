import 'package:genui/genui.dart';

import '../../auth/domain/auth_session.dart';
import '../../auth/domain/permission_policy.dart';
import '../../dashboard/domain/dashboard_repository.dart';
import '../../reports/domain/report_entity.dart';
import 'procurement_assistant_catalog.dart';

class ProcurementAssistantRequestContext {
  const ProcurementAssistantRequestContext({
    required this.session,
    this.dashboardCards = const [],
  });

  final AuthSession? session;
  final List<DashboardSummaryCard> dashboardCards;
}

class ProcurementAssistantResponse {
  const ProcurementAssistantResponse({required this.summaryText});

  final String summaryText;
}

class ProcurementAssistantAdapter {
  static const surfaceId = 'procurement-assistant-main';

  Future<ProcurementAssistantResponse> respond({
    required ChatMessage message,
    required A2uiTransportAdapter transport,
    required ProcurementAssistantRequestContext context,
  }) async {
    final prompt = message.text.trim();
    final normalized = prompt.toLowerCase();
    final components = _componentsFor(normalized, context);

    transport
      ..addMessage(
        const CreateSurface(
          surfaceId: surfaceId,
          catalogId: procurementAssistantCatalogId,
        ),
      )
      ..addMessage(
        UpdateComponents(surfaceId: surfaceId, components: components),
      );

    return ProcurementAssistantResponse(
      summaryText: _responseText(normalized, context),
    );
  }

  List<Component> _componentsFor(
    String normalizedPrompt,
    ProcurementAssistantRequestContext context,
  ) {
    final children = <String>[];
    final components = <Component>[];

    void add(Component component) {
      components.add(component);
      children.add(component.id);
    }

    add(
      _component('assistant-message', 'AssistantMessageCard', {
        'title': 'Procurement Assistant',
        'message': _messageFor(normalizedPrompt),
      }),
    );

    if (_isHome(normalizedPrompt) || normalizedPrompt.contains('summary')) {
      add(
        _component('assistant-summary', 'AssistantSummaryCards', {
          'cards': _summaryCards(context),
        }),
      );
    }

    if (_mentionsDraft(normalizedPrompt)) {
      add(
        _component('assistant-draft', 'AssistantDraftPreview', {
          'title': _draftTitle(normalizedPrompt),
          'priority': normalizedPrompt.contains('urgent') ? 'HIGH' : 'NORMAL',
          'neededBy': normalizedPrompt.contains('today')
              ? 'Today'
              : 'Choose in form',
          'route': '/requests/new',
          'items': _draftItems(normalizedPrompt),
        }),
      );
    }

    if (_mentionsReports(normalizedPrompt)) {
      final reportType = _reportTypeFor(normalizedPrompt);
      add(
        _component('assistant-report', 'AssistantReportFilterPreview', {
          'title': '${reportType.label} report preview',
          'route': reportType.route,
          'filters': _reportFilters(normalizedPrompt),
        }),
      );
    }

    if (_mentionsRfq(normalizedPrompt)) {
      add(
        _component('assistant-rfq', 'AssistantRfqInsight', {
          'title': 'RFQ comparison guidance',
          'route': '/rfqs',
          'bullets': [
            'Compare total cost, vendor reliability, delivery date, and quote completeness.',
            'Use the RFQ comparison screen to inspect submitted quotations.',
            'Winner selection remains in the controlled RFQ workflow.',
          ],
        }),
      );
    }

    if (_mentionsSync(normalizedPrompt)) {
      final pendingCount = _pendingSyncCount(context.dashboardCards);
      add(
        _component('assistant-sync', 'AssistantSyncStatus', {
          'title': 'Offline sync',
          'message': pendingCount > 0
              ? '$pendingCount item(s) are waiting to sync.'
              : 'No pending sync count is available from the dashboard.',
          'pendingCount': pendingCount,
          'route': '/sync-status',
        }),
      );
    }

    add(
      _component('assistant-actions', 'AssistantActionList', {
        'title': 'Safe actions',
        'actions': _safeActions(context, normalizedPrompt),
      }),
    );

    components.insert(
      0,
      _component('root', 'Column', {'align': 'stretch', 'children': children}),
    );
    return components;
  }

  String _messageFor(String normalizedPrompt) {
    if (_mentionsDraft(normalizedPrompt)) {
      return 'I prepared a draft preview. Open the form to review, edit, save, or submit through the existing request workflow.';
    }
    if (_mentionsReports(normalizedPrompt)) {
      return 'I prepared report filters. Open the report screen to load, refine, and export using your permissions.';
    }
    if (_mentionsRfq(normalizedPrompt)) {
      return 'I can summarize how to compare RFQs, but winner selection stays inside the RFQ comparison screen.';
    }
    if (_mentionsSync(normalizedPrompt)) {
      return 'I found the offline sync entry point. Use it to review pending local changes before syncing.';
    }
    return 'Ask for a draft, report, RFQ comparison, sync status, or a workflow shortcut. I will only route you to existing screens for final actions.';
  }

  String _responseText(
    String normalizedPrompt,
    ProcurementAssistantRequestContext context,
  ) {
    if (_mentionsDraft(normalizedPrompt)) return 'Draft preview ready.';
    if (_mentionsReports(normalizedPrompt)) return 'Report preview ready.';
    if (_mentionsRfq(normalizedPrompt)) return 'RFQ guidance ready.';
    if (_mentionsSync(normalizedPrompt)) {
      return 'Sync status ready with ${_pendingSyncCount(context.dashboardCards)} pending item(s).';
    }
    return 'Assistant home ready.';
  }

  List<JsonMap> _summaryCards(ProcurementAssistantRequestContext context) {
    final session = context.session;
    final visibleDashboardCards = [
      for (final card in context.dashboardCards)
        if (card.requiredPermissions.isEmpty ||
            PermissionPolicy.hasAnyPermission(
              session,
              card.requiredPermissions,
            ))
          {'label': card.label, 'value': card.value, 'icon': card.key},
    ];
    if (visibleDashboardCards.isNotEmpty) {
      return visibleDashboardCards.take(6).toList();
    }

    return [
      if (_canOpen(context, '/requests'))
        {'label': 'My Requests', 'value': 'Open', 'icon': 'request'},
      if (_canOpen(context, '/approvals'))
        {'label': 'Approvals', 'value': 'Review', 'icon': 'approval'},
      if (_canOpen(context, '/rfqs'))
        {'label': 'RFQs', 'value': 'Compare', 'icon': 'rfq'},
      if (_canOpen(context, '/reports'))
        {'label': 'Reports', 'value': 'Filter', 'icon': 'report'},
      if (_canOpen(context, '/sync-status'))
        {'label': 'Offline Sync', 'value': 'Check', 'icon': 'sync'},
    ];
  }

  List<JsonMap> _safeActions(
    ProcurementAssistantRequestContext context,
    String normalizedPrompt,
  ) {
    final candidates = <JsonMap>[
      if (_mentionsDraft(normalizedPrompt))
        {
          'title': 'Open request form',
          'subtitle': 'Review the draft in the standard form',
          'route': '/requests/new',
          'icon': 'request',
        },
      if (_mentionsReports(normalizedPrompt))
        {
          'title': 'Open report',
          'subtitle': 'Apply filters and export if permitted',
          'route': _reportTypeFor(normalizedPrompt).route,
          'icon': 'report',
        },
      if (_mentionsRfq(normalizedPrompt))
        {
          'title': 'Open RFQs',
          'subtitle': 'Compare quotations and inspect details',
          'route': '/rfqs',
          'icon': 'rfq',
        },
      if (_mentionsSync(normalizedPrompt))
        {
          'title': 'Open sync status',
          'subtitle': 'Review pending offline changes',
          'route': '/sync-status',
          'icon': 'sync',
        },
      {
        'title': 'My Requests',
        'subtitle': 'Track and edit permitted purchase requests',
        'route': '/requests',
        'icon': 'request',
      },
      {
        'title': 'Create Request',
        'subtitle': 'Start the deterministic request form',
        'route': '/requests/new',
        'icon': 'request',
      },
      {
        'title': 'Approvals',
        'subtitle': 'Review pending approval work',
        'route': '/approvals',
        'icon': 'approval',
      },
      {
        'title': 'Vendors',
        'subtitle': 'Search and manage supplier records',
        'route': '/vendors',
        'icon': 'vendor',
      },
      {
        'title': 'RFQs',
        'subtitle': 'Open sourcing and quotation workflows',
        'route': '/rfqs',
        'icon': 'rfq',
      },
      {
        'title': 'Purchase Orders',
        'subtitle': 'Review issued and received POs',
        'route': '/purchase-orders',
        'icon': 'order',
      },
      {
        'title': 'Invoices',
        'subtitle': 'Track supplier invoices',
        'route': '/invoices',
        'icon': 'invoice',
      },
      {
        'title': 'Reports',
        'subtitle': 'Review spend and activity',
        'route': '/reports',
        'icon': 'report',
      },
      {
        'title': 'Notifications',
        'subtitle': 'Unread alerts and workflow updates',
        'route': '/notifications',
        'icon': 'notification',
      },
    ];

    final seen = <String>{};
    return [
      for (final action in candidates)
        if (seen.add(action['route'] as String) &&
            _canOpen(context, action['route'] as String))
          {...action, 'enabled': true},
    ].take(6).toList();
  }

  List<JsonMap> _draftItems(String normalizedPrompt) {
    if (normalizedPrompt.contains('laptop')) {
      return [
        {'name': 'Laptop', 'quantity': '1', 'unit': 'pcs'},
      ];
    }
    if (normalizedPrompt.contains('printer')) {
      return [
        {'name': 'Printer', 'quantity': '1', 'unit': 'pcs'},
      ];
    }
    if (normalizedPrompt.contains('office')) {
      return [
        {'name': 'Office supplies', 'quantity': '1', 'unit': 'lot'},
      ];
    }
    return [
      {'name': 'Requested item', 'quantity': '1', 'unit': 'pcs'},
    ];
  }

  String _draftTitle(String normalizedPrompt) {
    if (normalizedPrompt.contains('laptop')) return 'Laptop purchase request';
    if (normalizedPrompt.contains('printer')) return 'Printer purchase request';
    if (normalizedPrompt.contains('office')) return 'Office supplies request';
    return 'Purchase request draft';
  }

  List<JsonMap> _reportFilters(String normalizedPrompt) {
    return [
      {
        'label': 'Date range',
        'value': normalizedPrompt.contains('last month')
            ? 'Last month'
            : 'Current view',
      },
      {
        'label': 'Status',
        'value': normalizedPrompt.contains('pending') ? 'Pending' : 'Any',
      },
      {'label': 'Search', 'value': 'Set in report screen'},
    ];
  }

  ReportType _reportTypeFor(String normalizedPrompt) {
    if (normalizedPrompt.contains('approval')) return ReportType.approvals;
    if (normalizedPrompt.contains('order') || normalizedPrompt.contains('po')) {
      return ReportType.purchaseOrders;
    }
    if (normalizedPrompt.contains('invoice')) return ReportType.invoices;
    if (normalizedPrompt.contains('payment')) return ReportType.payments;
    return ReportType.purchaseRequests;
  }

  int _pendingSyncCount(List<DashboardSummaryCard> cards) {
    for (final card in cards) {
      if (card.key == 'pending_sync' || card.key == 'pendingSync') {
        return int.tryParse(card.value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    }
    return 0;
  }

  bool _canOpen(ProcurementAssistantRequestContext context, String route) {
    return PermissionPolicy.canViewRoute(context.session, route);
  }

  bool _isHome(String normalizedPrompt) {
    return normalizedPrompt.isEmpty ||
        normalizedPrompt == 'assistant home' ||
        normalizedPrompt.contains('home') ||
        normalizedPrompt.contains('help');
  }

  bool _mentionsDraft(String normalizedPrompt) {
    return normalizedPrompt.contains('draft') ||
        normalizedPrompt.contains('create') ||
        normalizedPrompt.contains('request') ||
        normalizedPrompt.contains('laptop') ||
        normalizedPrompt.contains('printer');
  }

  bool _mentionsReports(String normalizedPrompt) {
    return normalizedPrompt.contains('report') ||
        normalizedPrompt.contains('last month') ||
        normalizedPrompt.contains('export');
  }

  bool _mentionsRfq(String normalizedPrompt) {
    return normalizedPrompt.contains('rfq') ||
        normalizedPrompt.contains('quotation') ||
        normalizedPrompt.contains('quote');
  }

  bool _mentionsSync(String normalizedPrompt) {
    return normalizedPrompt.contains('sync') ||
        normalizedPrompt.contains('offline');
  }

  Component _component(String id, String type, JsonMap properties) {
    return Component(id: id, type: type, properties: properties);
  }
}
