import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow_app/widgets/app_state_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('AppLoadingState renders its optional contextual label',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const AppLoadingState(label: 'جارٍ تحميل البيانات…')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('جارٍ تحميل البيانات…'), findsOneWidget);
  });

  testWidgets('AppErrorState presents a recovery action when provided',
      (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      _wrap(
        AppErrorState(
          title: 'تعذر التحميل',
          message: 'حاول مرة أخرى.',
          actionLabel: 'إعادة المحاولة',
          onAction: () => retryCount += 1,
        ),
      ),
    );

    expect(find.text('تعذر التحميل'), findsOneWidget);
    expect(find.text('حاول مرة أخرى.'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    expect(retryCount, 1);
  });

  testWidgets('AppEmptyState does not expose an action without a callback',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'لا توجد بيانات',
          message: 'أضف عنصرًا للبدء.',
          actionLabel: 'إضافة',
        ),
      ),
    );

    expect(find.text('لا توجد بيانات'), findsOneWidget);
    expect(find.text('إضافة'), findsNothing);
  });
}
