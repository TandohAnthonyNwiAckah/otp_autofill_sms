package com.tanacom.otp_autofill_sms


/** MyListener **/
interface MyListener {
    fun onOtpReceived(message: String?)
    fun onOtpTimeout()

}