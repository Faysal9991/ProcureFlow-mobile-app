import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.empty,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (value) {
        if (empty != null && _isEmpty(value)) {
          return empty!;
        }
        return data(value);
      },
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  bool _isEmpty(Object? value) {
    if (value == null) {
      return true;
    }
    if (value is Iterable) {
      return value.isEmpty;
    }
    if (value is Map) {
      return value.isEmpty;
    }
    if (value is String) {
      return value.isEmpty;
    }
    return false;
  }
}
