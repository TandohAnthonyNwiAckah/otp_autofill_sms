import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sms_otp_autofill_platform_interface.dart';

/// An implementation of [SmsOtpAutofillPlatform] that uses method channels.
class MethodChannelSmsOtpAutofill extends SmsOtpAutofillPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sms_otp_autofill');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
