import 'package:equatable/equatable.dart';

class AssistantTranscriptEntry extends Equatable {
  const AssistantTranscriptEntry({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  List<Object?> get props => [text, isUser];
}

class ProcurementAssistantState extends Equatable {
  const ProcurementAssistantState({
    this.isWaiting = false,
    this.errorMessage,
    this.surfaceIds = const [],
    this.transcript = const [],
  });

  final bool isWaiting;
  final String? errorMessage;
  final List<String> surfaceIds;
  final List<AssistantTranscriptEntry> transcript;

  ProcurementAssistantState copyWith({
    bool? isWaiting,
    String? errorMessage,
    bool clearError = false,
    List<String>? surfaceIds,
    List<AssistantTranscriptEntry>? transcript,
  }) {
    return ProcurementAssistantState(
      isWaiting: isWaiting ?? this.isWaiting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      surfaceIds: surfaceIds ?? this.surfaceIds,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  List<Object?> get props => [isWaiting, errorMessage, surfaceIds, transcript];
}
