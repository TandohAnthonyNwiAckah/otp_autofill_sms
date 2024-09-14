package com.tanacom.otp_autofill_sms

import android.annotation.SuppressLint
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.util.Arrays


/** MyApp **/
class MyApp(context: Context) : ContextWrapper(context) {

    companion object {
        val TAG = MyApp::class.java.simpleName
        private const val HASH_TYPE = "SHA-256"
        const val NUM_HASHED_BYTES = 9
        const val NUM_BASE64_CHAR = 11
    }

    fun getAppSignatures(): ArrayList<String> {
        val appCodes = ArrayList<String>()

        return try {
            // Get all package signatures for the current package
            val packageName = packageName
            val packageManager = packageManager

            // Check Android version to decide which method to use
            val signatures: Array<Signature>? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    // For Android P (API level 28) and above
                    val signingInfo = packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNING_CERTIFICATES
                    ).signingInfo

                    if (signingInfo.hasMultipleSigners()) {
                        signingInfo.apkContentsSigners
                    }
                    //
                    else {
                        signingInfo.signingCertificateHistory
                    }
                }
                //
                else {
                    // For Android versions below API level 28
                    @Suppress("DEPRECATION")
                    packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNATURES
                    ).signatures
                }

            // For each signature, create a compatible hash
            signatures?.mapNotNull { hash(packageName, it.toCharsString()) }?.mapTo(appCodes) { it }
            appCodes
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e(TAG, "Unable to find package to obtain hash.", e)
            ArrayList()
        }
    }

    @SuppressLint("NewApi")
    private fun hash(packageName: String, signature: String): String? {
        val appInfo = "$packageName $signature"
        return try {
            val messageDigest = MessageDigest.getInstance(HASH_TYPE)
            messageDigest.update(appInfo.toByteArray(StandardCharsets.UTF_8))
            var hashSignature = messageDigest.digest()

            // truncated into NUM_HASHED_BYTES
            hashSignature = Arrays.copyOfRange(hashSignature, 0, NUM_HASHED_BYTES)
            // encode into Base64
            var base64Hash =
                Base64.encodeToString(hashSignature, Base64.NO_PADDING or Base64.NO_WRAP)
            base64Hash = base64Hash.substring(0, NUM_BASE64_CHAR)

            base64Hash
        } catch (e: NoSuchAlgorithmException) {
            Log.e(TAG, "NoSuchAlgorithm", e)
            null
        }
    }

}