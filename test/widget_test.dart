import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow_app/main.dart';

void main() {
  testWidgets('Task Flow app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());

    expect(find.byType(TaskFlowApp), findsOneWidget);
  });
}
