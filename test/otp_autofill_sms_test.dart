import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otp_autofill_sms/src/otp_autofill_sms_method_channel.dart';

void main() {
  const MethodChannel channel = MethodChannel('otp_autofill_sms');

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
    final version = await OtpAutofillSms.getPlatformVersion();
    expect(version, '42');
  });
}
