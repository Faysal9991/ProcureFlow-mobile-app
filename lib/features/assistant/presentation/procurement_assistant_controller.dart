import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';

import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/domain/dashboard_repository.dart';
import 'assistant_state.dart';
import 'procurement_assistant_adapter.dart';
import 'procurement_assistant_catalog.dart';

final procurementAssistantControllerProvider =
    StateNotifierProvider.autoDispose<
      ProcurementAssistantController,
      ProcurementAssistantState
    >((ref) {
      final session = ref.watch(authControllerProvider).session;
      return ProcurementAssistantController(session: session);
    });

class ProcurementAssistantController
    extends StateNotifier<ProcurementAssistantState> {
  ProcurementAssistantController({required AuthSession? session})
    : _session = session,
      super(const ProcurementAssistantState()) {
    _surfaceController = SurfaceController(
      catalogs: [procurementAssistantCatalog()],
    );
    late final A2uiTransportAdapter transport;
    transport = A2uiTransportAdapter(
      onSend: (message) => _handleSend(message, transport),
    );
    _transport = transport;
    _conversation = Conversation(
      controller: _surfaceController,
      transport: _transport,
    );
    _eventsSubscription = _conversation.events.listen(_handleEvent);
  }

  final AuthSession? _session;
  final _adapter = ProcurementAssistantAdapter();

  late final SurfaceController _surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  StreamSubscription<ConversationEvent>? _eventsSubscription;

  ProcurementAssistantRequestContext? _activeContext;
  ProcurementAssistantResponse? _lastResponse;

  SurfaceContext surfaceContextFor(String surfaceId) {
    return _surfaceController.contextFor(surfaceId);
  }

  Future<void> showHome({required List<DashboardSummaryCard> dashboardCards}) {
    return _sendPrompt(
      'assistant home',
      dashboardCards: dashboardCards,
      recordUserPrompt: false,
      recordAssistantResponse: false,
    );
  }

  Future<void> sendPrompt(
    String prompt, {
    required List<DashboardSummaryCard> dashboardCards,
  }) {
    return _sendPrompt(prompt, dashboardCards: dashboardCards);
  }

  Future<void> _sendPrompt(
    String prompt, {
    required List<DashboardSummaryCard> dashboardCards,
    bool recordUserPrompt = true,
    bool recordAssistantResponse = true,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isWaiting) return;

    _activeContext = ProcurementAssistantRequestContext(
      session: _session,
      dashboardCards: dashboardCards,
    );
    _lastResponse = null;
    state = state.copyWith(
      isWaiting: true,
      clearError: true,
      transcript: [
        ...state.transcript,
        if (recordUserPrompt)
          AssistantTranscriptEntry(text: trimmed, isUser: true),
      ],
    );

    await _conversation.sendRequest(ChatMessage.user(trimmed));

    final response = _lastResponse;
    state = state.copyWith(
      isWaiting: false,
      transcript: [
        ...state.transcript,
        if (recordAssistantResponse && response != null)
          AssistantTranscriptEntry(text: response.summaryText, isUser: false),
      ],
    );
  }

  Future<void> _handleSend(
    ChatMessage message,
    A2uiTransportAdapter transport,
  ) async {
    final context =
        _activeContext ?? ProcurementAssistantRequestContext(session: _session);
    _lastResponse = await _adapter.respond(
      message: message,
      transport: transport,
      context: context,
    );
  }

  void _handleEvent(ConversationEvent event) {
    switch (event) {
      case ConversationSurfaceAdded():
      case ConversationComponentsUpdated():
      case ConversationSurfaceRemoved():
        state = state.copyWith(
          surfaceIds: _surfaceController.activeSurfaceIds.toList(),
        );
      case ConversationContentReceived():
      case ConversationWaiting():
        break;
      case ConversationError(:final error):
        state = state.copyWith(
          isWaiting: false,
          errorMessage: _messageFromError(error),
        );
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _conversation.dispose();
    _transport.dispose();
    _surfaceController.dispose();
    super.dispose();
  }
}
