import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:spendhike/main.dart';
import 'package:spendhike/services/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App root widget loads MaterialApp smoke test', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await AppSettings.instance.init();
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
