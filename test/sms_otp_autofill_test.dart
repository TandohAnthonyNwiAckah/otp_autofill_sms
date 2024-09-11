import 'package:flutter_test/flutter_test.dart';
import 'package:sms_otp_autofill/sms_otp_autofill.dart';
import 'package:sms_otp_autofill/sms_otp_autofill_platform_interface.dart';
import 'package:sms_otp_autofill/sms_otp_autofill_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmsOtpAutofillPlatform
    with MockPlatformInterfaceMixin
    implements SmsOtpAutofillPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SmsOtpAutofillPlatform initialPlatform = SmsOtpAutofillPlatform.instance;

  test('$MethodChannelSmsOtpAutofill is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSmsOtpAutofill>());
  });

  test('getPlatformVersion', () async {
    SmsOtpAutofill smsOtpAutofillPlugin = SmsOtpAutofill();
    MockSmsOtpAutofillPlatform fakePlatform = MockSmsOtpAutofillPlatform();
    SmsOtpAutofillPlatform.instance = fakePlatform;

    expect(await smsOtpAutofillPlugin.getPlatformVersion(), '42');
  });
}
