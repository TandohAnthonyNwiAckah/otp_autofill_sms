import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sms_otp_autofill_method_channel.dart';

abstract class SmsOtpAutofillPlatform extends PlatformInterface {
  /// Constructs a SmsOtpAutofillPlatform.
  SmsOtpAutofillPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmsOtpAutofillPlatform _instance = MethodChannelSmsOtpAutofill();

  /// The default instance of [SmsOtpAutofillPlatform] to use.
  ///
  /// Defaults to [MethodChannelSmsOtpAutofill].
  static SmsOtpAutofillPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SmsOtpAutofillPlatform] when
  /// they register themselves.
  static set instance(SmsOtpAutofillPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
