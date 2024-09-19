package com.tanacom.otp_autofill_sms

/**
 * MyListener interface to handle OTP events.
 */
interface MyListener {
    /**
     * Called when an OTP is received.
     * @param message The received OTP message.
     */
    fun onOtpReceived(message: String?)

    /**
     * Called when OTP retrieval times out.
     */
    fun onOtpTimeout()
}