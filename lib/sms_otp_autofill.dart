
import 'sms_otp_autofill_platform_interface.dart';

class SmsOtpAutofill {
  Future<String?> getPlatformVersion() {
    return SmsOtpAutofillPlatform.instance.getPlatformVersion();
  }
}
