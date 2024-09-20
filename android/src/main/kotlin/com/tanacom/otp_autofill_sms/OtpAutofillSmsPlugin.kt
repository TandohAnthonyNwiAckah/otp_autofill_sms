package com.tanacom.otp_autofill_sms

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.IntentSender
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log
import com.google.android.gms.auth.api.identity.GetPhoneNumberHintIntentRequest
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.auth.api.identity.SignInClient
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.auth.api.phone.SmsRetrieverClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry

/**
 * OtpAutofillSmsPlugin
 * A Flutter plugin to handle OTP autofill via SMS and phone number hint retrieval.
 */
class OtpAutofillSmsPlugin : FlutterPlugin, MethodCallHandler, MyListener, ActivityAware {

    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null
    private var receiver: SmsReceiver? = null
    private var alreadyCalledSmsRetrieve = false
    private var client: SmsRetrieverClient? = null
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null
    private var oneTapClient: SignInClient? = null


    /**
     * Listener for activity result to handle phone number hint selection.
     */
    private val activityResultListener: PluginRegistry.ActivityResultListener =
        object : PluginRegistry.ActivityResultListener {
            override fun onActivityResult(
                requestCode: Int,
                resultCode: Int,
                data: Intent?
            ): Boolean {
                if (requestCode == REQUEST_RESOLVE_HINT) {
                    if (resultCode == Activity.RESULT_OK && data != null) {
                        // Phone number selection success
                        val phoneNumber = data.getStringExtra("phoneNumber")
                        pendingResult?.success(phoneNumber)
                    } else {
                        pendingResult?.success(null)
                    }
                    return true
                }
                return false
            }
        }

    companion object {
        private const val CHANNEL_NAME = "otp_autofill_sms"
        private const val REQUEST_RESOLVE_HINT = 1256


        /**
         * Setup method to initialize the plugin.
         * @param plugin The instance of OtpAutofillSmsPlugin.
         * @param binaryMessenger The BinaryMessenger for communication.
         */
        @JvmStatic
        fun setup(plugin: OtpAutofillSmsPlugin, binaryMessenger: BinaryMessenger) {
            plugin.channel = MethodChannel(binaryMessenger, CHANNEL_NAME)
            plugin.channel?.setMethodCallHandler(plugin)
            plugin.binding?.addActivityResultListener(plugin.activityResultListener)
        }
    }


    // This method is called when the plugin is attached to the Flutter engine.
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        setup(plugin = this, binding.binaryMessenger)
    }


    // This method is called when the plugin is detached from the Flutter engine.
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregister()
    }


    // This method is called when a method is called on the channel.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "getAppSignature" -> {
                activity?.let {
                    val signature = MyApp(it).getAppSignatures()[0]
                    result.success(signature)
                }
            }

            "startListening" -> {
                this.pendingResult = result
                receiver = SmsReceiver()
                startListening()
            }

            "stopListening" -> {
                pendingResult = null
                unregister()
            }

            "requestPhoneHint" -> {
                this.pendingResult = result
                requestHint()
            }

            else -> result.notImplemented()
        }
    }


    /**
     * Requests a phone number hint using the Google Identity API.
     */
    private fun requestHint() {
        if (!isSimSupport()) {
            pendingResult?.success(null)
            return
        }

        // Initialize the new Identity API client
        oneTapClient = Identity.getSignInClient(activity!!)

        // Build the GetPhoneNumberHintIntentRequest for phone number hint
        val hintRequest = GetPhoneNumberHintIntentRequest.builder().build()

        oneTapClient?.getPhoneNumberHintIntent(hintRequest)
            ?.addOnSuccessListener { result ->
                try {
                    activity?.startIntentSenderForResult(
                        result.intentSender,
                        REQUEST_RESOLVE_HINT, null, 0, 0, 0
                    )
                } catch (e: IntentSender.SendIntentException) {
                    e.printStackTrace()
                }
            }
            ?.addOnFailureListener { e ->
                Log.e("OtpAutofillSmsPlugin", "Error retrieving phone number hint: ${e.message}")
                pendingResult?.success(null)
            }
    }


    /**
     * Checks if the device has SIM support.
     * @return True if SIM is supported, false otherwise.
     */
    private fun isSimSupport(): Boolean {
        val telephonyManager: TelephonyManager =
            activity!!.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        return (telephonyManager.simState != TelephonyManager.SIM_STATE_ABSENT)
    }


    /**
     * Starts listening for SMS messages using the SMS Retriever API.
     */
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun startListening() {
        activity?.let {
            client = SmsRetriever.getClient(it)
        }
        val task = client?.startSmsRetriever()
        task?.addOnSuccessListener {
            unregister()
            Log.e(javaClass.simpleName, "SMS retriever started")
            receiver?.setSmsListener(this)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity?.registerReceiver(
                    receiver, IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION),
                    Context.RECEIVER_EXPORTED
                )
            } else {
                activity?.registerReceiver(
                    receiver,
                    IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
                )
            }
        }
    }


    /**
     * Unregisters the SMS receiver.
     */
    private fun unregister() {
        alreadyCalledSmsRetrieve = false
        receiver?.let {
            try {
                activity?.unregisterReceiver(it)
                Log.d(javaClass.simpleName, "SMS retriever stopped")
                receiver = null
            } catch (_: Exception) {
            }
        }
    }


    // This method is called when an OTP is received.
    override fun onOtpReceived(message: String?) {
        message?.let {
            if (!alreadyCalledSmsRetrieve) {
                pendingResult?.success(it)
                alreadyCalledSmsRetrieve = true
            } else {
                Log.d("onOtpReceived: ", "already called")
            }
        }
    }


    // This method is called when the OTP retrieval times out.
    override fun onOtpTimeout() {}


    // This method is called when the plugin is attached to an activity.
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        this.binding = binding
        binding.addActivityResultListener(activityResultListener)
    }


    // This method is called when the plugin is detached from an activity for configuration changes.
    override fun onDetachedFromActivityForConfigChanges() {
        unregister()
    }


    // This method is called when the plugin is reattached to an activity for configuration changes.
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        this.binding = binding
        binding.addActivityResultListener(activityResultListener)
    }



    // This method is called when the plugin is detached from an activity.
    override fun onDetachedFromActivity() {
        unregister()
    }


}