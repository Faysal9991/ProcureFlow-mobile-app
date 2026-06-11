import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procurement_management/core/widgets/status_chip.dart';

void main() {
  testWidgets('status tones match production status map', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      statusToneFor(capturedContext, 'DRAFT').kind,
      StatusToneKind.neutral,
    );
    expect(
      statusToneFor(capturedContext, 'SUBMITTED').kind,
      StatusToneKind.info,
    );
    expect(statusToneFor(capturedContext, 'OPEN').kind, StatusToneKind.info);
    expect(
      statusToneFor(capturedContext, 'PENDING').kind,
      StatusToneKind.warning,
    );
    expect(
      statusToneFor(capturedContext, 'PARTIALLY_PAID').kind,
      StatusToneKind.warning,
    );
    expect(
      statusToneFor(capturedContext, 'APPROVED').kind,
      StatusToneKind.success,
    );
    expect(statusToneFor(capturedContext, 'PAID').kind, StatusToneKind.success);
    expect(
      statusToneFor(capturedContext, 'REJECTED').kind,
      StatusToneKind.error,
    );
    expect(
      statusToneFor(capturedContext, 'OVERDUE').kind,
      StatusToneKind.error,
    );
    expect(
      statusToneFor(capturedContext, 'CANCELLED').kind,
      StatusToneKind.cancelled,
    );
    expect(
      statusToneFor(capturedContext, 'ISSUED').kind,
      StatusToneKind.issued,
    );
    expect(
      statusToneFor(capturedContext, 'RECEIVED').kind,
      StatusToneKind.received,
    );
  });

  test('status labels normalize separators', () {
    expect(statusLabel('partially-paid'), 'PARTIALLY PAID');
    expect(statusLabel('pending sync'), 'PENDING SYNC');
  });
}
