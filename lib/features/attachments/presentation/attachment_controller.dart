import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/attachment_repository.dart';
import 'attachment_providers.dart';
import 'attachment_state.dart';

final attachmentControllerProvider =
    StateNotifierProvider.autoDispose<AttachmentController, AttachmentState>(
      (ref) => AttachmentController(ref.watch(attachmentRepositoryProvider)),
    );

class AttachmentController extends StateNotifier<AttachmentState> {
  AttachmentController(this._repository) : super(const AttachmentState());

  final AttachmentRepository _repository;

  Future<void> load({
    required String entityType,
    required String entityId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repository.getAttachments(
        entityType: entityType,
        entityId: entityId,
      );
      state = state.copyWith(isLoading: false, items: page.items);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<void> upload({
    required String entityType,
    required String entityId,
    required File file,
  }) async {
    state = state.copyWith(
      isMutating: true,
      clearError: true,
      clearProgress: true,
    );
    try {
      await _repository.uploadAttachment(
        entityType: entityType,
        entityId: entityId,
        file: file,
        onSendProgress: _setProgress,
      );
      await load(entityType: entityType, entityId: entityId);
      state = state.copyWith(isMutating: false, progress: 1);
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  Future<String?> download({
    required String id,
    required String fileName,
  }) async {
    state = state.copyWith(
      isMutating: true,
      clearError: true,
      clearProgress: true,
    );
    try {
      final path = await _repository.downloadAttachment(
        id: id,
        fileName: fileName,
        onReceiveProgress: _setProgress,
      );
      state = state.copyWith(isMutating: false, progress: 1);
      return path;
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
      return null;
    }
  }

  Future<void> delete({
    required String id,
    required String entityType,
    required String entityId,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await _repository.deleteAttachment(id);
      await load(entityType: entityType, entityId: entityId);
      state = state.copyWith(isMutating: false);
    } catch (error) {
      state = state.copyWith(
        isMutating: false,
        errorMessage: _messageFromError(error),
      );
    }
  }

  void _setProgress(int done, int total) {
    if (total <= 0) return;
    state = state.copyWith(progress: done / total);
  }

  String _messageFromError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.startsWith('Invalid argument(s): ')) {
      return message.substring('Invalid argument(s): '.length);
    }
    if (message.startsWith('Bad state: ')) {
      return message.substring('Bad state: '.length);
    }
    return message;
  }
}
