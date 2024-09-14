package com.tanacom.otp_autofill_sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status


/** SmsReceiver **/
class SmsReceiver : BroadcastReceiver() {

    private var mySmsListener: MyListener? = null

    fun setSmsListener(listener: MyListener) {
        mySmsListener = listener
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (SmsRetriever.SMS_RETRIEVED_ACTION == intent.action) {
            val extras = intent.extras
            val status = extras?.get(SmsRetriever.EXTRA_STATUS) as? Status

            when (status?.statusCode) {
                CommonStatusCodes.SUCCESS -> {
                    // Get SMS message contents
                    val sms = extras.get(SmsRetriever.EXTRA_SMS_MESSAGE) as? String
                    sms?.let {
                        mySmsListener?.onOtpReceived(it)
                    }
                }

                CommonStatusCodes.TIMEOUT -> {
                    mySmsListener?.onOtpTimeout()
                }

                else -> {
                    // Handle other status codes if necessary
                }
            }
        }
    }
}
