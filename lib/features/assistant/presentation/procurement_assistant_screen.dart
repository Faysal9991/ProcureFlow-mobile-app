import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genui/genui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/domain/dashboard_repository.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import 'procurement_assistant_controller.dart';

class ProcurementAssistantScreen extends ConsumerStatefulWidget {
  const ProcurementAssistantScreen({
    super.key,
    this.showBottomNavigation = true,
  });

  final bool showBottomNavigation;

  @override
  ConsumerState<ProcurementAssistantScreen> createState() =>
      _ProcurementAssistantScreenState();
}

class _ProcurementAssistantScreenState
    extends ConsumerState<ProcurementAssistantScreen> {
  final _promptController = TextEditingController();
  bool _loadedHome = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(procurementAssistantControllerProvider);
    final controller = ref.read(
      procurementAssistantControllerProvider.notifier,
    );
    final dashboardCards = ref.watch(dashboardControllerProvider).cards;
    final session = ref.watch(authControllerProvider).session;

    if (!_loadedHome) {
      _loadedHome = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.showHome(dashboardCards: dashboardCards);
      });
    }

    return AppScaffold(
      title: 'AI Assistant',
      showBottomNavigation: widget.showBottomNavigation,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: AppInsets.screen,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppBreakpoints.contentMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PromptChips(
                          onSelected: (prompt) =>
                              _sendPrompt(prompt, controller, dashboardCards),
                        ),
                        const SizedBox(height: 14),
                        if (state.errorMessage != null)
                          AppErrorCard(message: state.errorMessage!)
                        else if (state.surfaceIds.isEmpty)
                          const AppLoadingCard(
                            message: 'Preparing assistant...',
                          )
                        else
                          for (final surfaceId in state.surfaceIds)
                            Surface(
                              key: ValueKey(surfaceId),
                              surfaceContext: controller.surfaceContextFor(
                                surfaceId,
                              ),
                              actionDelegate:
                                  ProcurementAssistantActionDelegate(
                                    session: session,
                                  ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _AssistantComposer(
            controller: _promptController,
            isWaiting: state.isWaiting,
            onSubmit: (prompt) =>
                _sendPrompt(prompt, controller, dashboardCards),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPrompt(
    String prompt,
    ProcurementAssistantController controller,
    List<DashboardSummaryCard> dashboardCards,
  ) async {
    await controller.sendPrompt(prompt, dashboardCards: dashboardCards);
    if (mounted) _promptController.clear();
  }
}

class _PromptChips extends StatelessWidget {
  const _PromptChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'Show my summary',
      'Create a laptop request',
      'Purchase order report from last month',
      'RFQ quotation comparison',
      'Offline sync status',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final prompt in prompts)
          ActionChip(
            label: Text(prompt),
            avatar: const Icon(AppIcons.assistant, size: 16),
            onPressed: () => onSelected(prompt),
          ),
      ],
    );
  }
}

class _AssistantComposer extends StatelessWidget {
  const _AssistantComposer({
    required this.controller,
    required this.isWaiting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isWaiting;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWaiting) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('assistantPromptField'),
                      controller: controller,
                      enabled: !isWaiting,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about requests, reports, RFQs, or sync',
                        prefixIcon: Icon(AppIcons.assistant),
                      ),
                      onSubmitted: isWaiting ? null : _submit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    key: const Key('assistantSendButton'),
                    tooltip: 'Send',
                    onPressed: isWaiting
                        ? null
                        : () => _submit(controller.text),
                    icon: const Icon(AppIcons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(String value) {
    final prompt = value.trim();
    if (prompt.isEmpty) return;
    onSubmit(prompt);
  }
}

class ProcurementAssistantActionDelegate implements ActionDelegate {
  const ProcurementAssistantActionDelegate({required this.session});

  final AuthSession? session;

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    if (event is! UserActionEvent || event.name != 'assistant.navigate') {
      return false;
    }

    final route = event.context['route']?.toString() ?? '';
    if (route.isEmpty) return true;

    if (!PermissionPolicy.canViewRoute(session, route)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to open this page.'),
        ),
      );
      return true;
    }

    context.go(route);
    return true;
  }
}
