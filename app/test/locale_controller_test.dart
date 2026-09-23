import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/core/locale_controller.dart';

void main() {
  final controller = LocaleController.instance;

  testWidgets('resolvedLanguageCode covers every shipped locale',
      (tester) async {
    addTearDown(() => controller.value = null);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    // An explicit choice wins over the device.
    tester.platformDispatcher.localesTestValue = const [Locale('ko')];
    for (final code in ['en', 'ko', 'ja', 'zh', 'es']) {
      controller.value = Locale(code);
      expect(controller.resolvedLanguageCode, code);
    }

    // Following the device: the first device language the app ships.
    controller.value = null;
    tester.platformDispatcher.localesTestValue = const [
      Locale('fr'),
      Locale('ja'),
    ];
    expect(controller.resolvedLanguageCode, 'ja');

    // Nothing shipped on the device: English.
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    expect(controller.resolvedLanguageCode, 'en');
  });
}
