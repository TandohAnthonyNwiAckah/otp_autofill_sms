import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:otp_autofill_sms/otp_autofill_sms.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  // String _platformVersion = 'Unknown';
  final int _otpLength = 6;
  bool _isLoading = false;
  bool _enableButton = false;
  String _otpCode = "";
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final intRegex = RegExp(r'\d+', multiLine: true);

  TextEditingController otpTextFieldController =
      TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    // initPlatformState();
    _getSignatureCode();
    _startListeningSms();
  }

  /// Initialize platform state
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await OtpAutofillSms.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      if (kDebugMode) {
        print(platformVersion);
      }
      // _platformVersion = platformVersion;
    });
  }

  @override
  void dispose() {
    super.dispose();
    OtpAutofillSms.stopListening();
    otpTextFieldController.dispose();
  }

  /// Get the app signature code
  _getSignatureCode() async {
    String? signature = await OtpAutofillSms.getAppSignature();
    if (kDebugMode) {
      print("signature $signature");
    }
  }

  /// Start listening for SMS messages
  _startListeningSms() {
    OtpAutofillSms.startListeningSms().then((message) {
      setState(() {
        _otpCode = OtpAutofillSms.getCode(message, intRegex);
        otpTextFieldController.text = _otpCode;
        _onOtpCallBack(_otpCode, true);
      });
    });
  }

  /// Handle OTP submission
  _onSubmitOtp() {
    setState(() {
      _isLoading = !_isLoading;
      _verifyOtpCode();
    });
  }

  /// Handle OTP submission
  _onClickRetry() {
    _startListeningSms();
  }

  /// Callback for OTP changes
  _onOtpCallBack(String otpCode, bool isAutofill) {
    setState(() {
      _otpCode = otpCode;
      if (otpCode.length == _otpLength && isAutofill) {
        _enableButton = false;
        _isLoading = true;
        _verifyOtpCode();
      }
      //
      else if (otpCode.length == _otpLength && !isAutofill) {
        _enableButton = true;
        _isLoading = false;
      }
      //
      else {
        _enableButton = false;
      }
    });
  }

  /// Verify the OTP code
  _verifyOtpCode() {
    FocusScope.of(context).requestFocus(FocusNode());

    Timer(const Duration(milliseconds: 4000), () {
      setState(() {
        _isLoading = false;
        _enableButton = false;
      });
    });

    Fluttertoast.showToast(
        msg: "OTP CODE IS VERIFIED",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('OTP autofill sms example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.network(
                      "https://i.ibb.co/7vGxvTd/ic-verify.png",
                      fit: BoxFit.fill,
                    )),
              ),
              const SizedBox(
                height: 12,
              ),
              Column(
                children: [
                  const Text(
                    "OTP Verification",
                    style: TextStyle(
                      color: Color(0xFF5B5B5B),
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  OtpTextField(
                      textController: otpTextFieldController,
                      autoFocus: true,
                      codeLength: _otpLength,
                      alignment: MainAxisAlignment.center,
                      defaultBoxSize: 35.0,
                      margin: 10,
                      selectedBoxSize: 35.0,
                      textStyle: const TextStyle(fontSize: 16),
                      defaultDecoration: _pinPutDecoration.copyWith(
                          border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.6))),
                      selectedDecoration: _pinPutDecoration,
                      onChange: (code) {
                        _onOtpCallBack(code, false);
                      }),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn’t you receive the OTP? ",
                        style: TextStyle(
                          color: Color(0xFF5B5B5B),
                        ),
                      ),
                      TextButton(
                        onPressed: _onClickRetry,
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  SizedBox(
                    width: double.maxFinite,
                    height: 80,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: MaterialButton(
                          onPressed: _enableButton ? _onSubmitOtp : null,
                          color: Colors.deepOrange,
                          disabledColor: Colors.deepOrange[100],
                          child: buttonVerify(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget for the verify button
  Widget buttonVerify() {
    if (_isLoading) {
      return const SizedBox(
        width: 19,
        height: 19,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    //
    else {
      return const Text(
        "Verify",
        style: TextStyle(color: Colors.white),
      );
    }
  }

  /// Decoration for the OTP input fields
  BoxDecoration get _pinPutDecoration {
    return BoxDecoration(
      border: Border.all(color: Theme.of(context).primaryColor),
      borderRadius: BorderRadius.circular(15.0),
    );
  }
}
