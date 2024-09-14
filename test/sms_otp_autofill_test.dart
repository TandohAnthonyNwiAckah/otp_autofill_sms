import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_otp_autofill/src/sms_otp_autofill_method_channel.dart'; // Ensure this import path is correct

void main() {
  const MethodChannel channel = MethodChannel('sms_otp_autofill');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return '42';
      }
      throw PlatformException(
        code: 'Unimplemented',
        details: 'The ${methodCall.method} method is not implemented',
      );
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    final version = await SmsAutofill.getPlatformVersion();
    expect(version, '42');
  });
}
