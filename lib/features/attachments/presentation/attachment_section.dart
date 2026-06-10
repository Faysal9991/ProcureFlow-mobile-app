import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/app_components.dart';
import '../data/attachment_repository_impl.dart';
import '../domain/attachment_entity.dart';
import 'attachment_controller.dart';

class AttachmentSection extends ConsumerStatefulWidget {
  const AttachmentSection({
    super.key,
    required this.entityType,
    required this.entityId,
    this.canUpload = true,
    this.canDelete = true,
  });

  final String entityType;
  final String entityId;
  final bool canUpload;
  final bool canDelete;

  @override
  ConsumerState<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends ConsumerState<AttachmentSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void didUpdateWidget(covariant AttachmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityId != widget.entityId ||
        oldWidget.entityType != widget.entityType) {
      Future.microtask(_load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attachmentControllerProvider);
    final date = DateFormat.yMMMd().add_jm();
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attachments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.canUpload)
                IconButton(
                  key: const Key('uploadAttachmentButton'),
                  tooltip: 'Upload attachment',
                  onPressed: state.isMutating ? null : _pickAndUpload,
                  icon: const Icon(AppIcons.upload),
                ),
            ],
          ),
          if (state.isMutating && state.progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: state.progress),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 8),
          if (state.isLoading && state.items.isEmpty)
            const Text('Loading attachments...')
          else if (state.items.isEmpty)
            const Text('No attachments.')
          else
            for (final item in state.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(AppIcons.file),
                title: Text(item.fileName),
                subtitle: Text(
                  '${_fileSize(item.fileSize)} • ${date.format(item.createdAt)}',
                ),
                onTap: () => _downloadAndOpen(item),
                trailing: widget.canDelete
                    ? IconButton(
                        tooltip: 'Delete attachment',
                        icon: const Icon(AppIcons.trash),
                        onPressed: state.isMutating
                            ? null
                            : () => _confirmDelete(item),
                      )
                    : null,
              ),
        ],
      ),
    );
  }

  Future<void> _load() {
    return ref
        .read(attachmentControllerProvider.notifier)
        .load(entityType: widget.entityType, entityId: widget.entityId);
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: AttachmentRepositoryImpl.allowedExtensions.toList(),
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await ref
        .read(attachmentControllerProvider.notifier)
        .upload(
          entityType: widget.entityType,
          entityId: widget.entityId,
          file: File(path),
        );
  }

  Future<void> _downloadAndOpen(AttachmentFile item) async {
    final path = await ref
        .read(attachmentControllerProvider.notifier)
        .download(id: item.localId, fileName: item.fileName);
    if (!mounted || path == null) return;
    final result = await OpenFilex.open(path);
    if (result.type == ResultType.done) return;
    await SharePlus.instance.share(
      ShareParams(title: item.fileName, files: [XFile(path)]),
    );
  }

  Future<void> _confirmDelete(AttachmentFile item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete attachment?'),
        content: Text(item.fileName),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(attachmentControllerProvider.notifier)
        .delete(
          id: item.localId,
          entityType: widget.entityType,
          entityId: widget.entityId,
        );
  }

  String _fileSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
