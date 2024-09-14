package com.tanacom.sms_otp_autofill


/** MyListener **/
interface MyListener {
    fun onOtpReceived(message: String?)
    fun onOtpTimeout()

}