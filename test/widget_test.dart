// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campuslost/main.dart';

void main() {
  testWidgets('CampusFind loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger frames until all async futures settle.
    await tester.pumpWidget(const CampusFindApp());
    await tester.pumpAndSettle();

    // Verify that CampusFind branding is found.
    expect(find.textContaining('CampusFind'), findsWidgets);
  });

  test('SharedPreferences persistence and CampusItem serialization test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testItem = CampusItem(
      id: 'test-item-1',
      title: 'Lost Backpack',
      description: 'Black backpack left in library',
      category: 'Wallets & Bags',
      type: ItemType.lost,
      location: 'Central Library',
      date: 'Today',
      contactPerson: 'Jane Doe',
      contactInfo: 'jane@campus.edu',
    );

    // Verify serialization round-trip
    final jsonMap = testItem.toJson();
    final reconstructed = CampusItem.fromJson(jsonMap);
    expect(reconstructed.id, testItem.id);
    expect(reconstructed.title, testItem.title);
    expect(reconstructed.type, testItem.type);

    // Verify storage in SharedPreferences
    await prefs.setString('test_key', jsonMap['title'] as String);
    expect(prefs.getString('test_key'), 'Lost Backpack');
  });
}
