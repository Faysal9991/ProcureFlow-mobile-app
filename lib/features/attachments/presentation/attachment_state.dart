import 'package:equatable/equatable.dart';

import '../domain/attachment_entity.dart';

class AttachmentState extends Equatable {
  const AttachmentState({
    this.isLoading = false,
    this.isMutating = false,
    this.progress,
    this.errorMessage,
    this.items = const [],
  });

  final bool isLoading;
  final bool isMutating;
  final double? progress;
  final String? errorMessage;
  final List<AttachmentFile> items;

  AttachmentState copyWith({
    bool? isLoading,
    bool? isMutating,
    double? progress,
    bool clearProgress = false,
    String? errorMessage,
    bool clearError = false,
    List<AttachmentFile>? items,
  }) {
    return AttachmentState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      progress: clearProgress ? null : progress ?? this.progress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isMutating,
    progress,
    errorMessage,
    items,
  ];
}
