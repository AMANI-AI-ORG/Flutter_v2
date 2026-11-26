package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.BridgeLog

import ai.amani.sdk.Amani
import android.annotation.SuppressLint
import android.app.Activity
import android.graphics.Bitmap
import android.nfc.NfcAdapter
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class NFC {
    // Resolved lazily: the singleton is created before the SDK has been configured.
    private val NFCModule get() = Amani.sharedInstance().ScanNFC()
    private var docType: String = "XXX_NF_0"
    private var currentResult: MethodChannel.Result? = null
    private var nfcAdapter: NfcAdapter? = null

    private var activityRef: Activity? = null

    private var birthDate: String? = null
    private var expireDate: String? = null
    private var documentNo: String? = null

    companion object {
        // TODO: Refactor this
        val instance = NFC()
    }

    @SuppressLint("WrongConstant")
    fun start(birthDate: String?, expireDate: String?, documentNo: String?, activity: Activity, channel: MethodChannel, result: MethodChannel.Result) {
        BridgeLog.d("AmaniBridge", "[NFC] start called, usesNFC=${IdCapture.instance.usesNFC}")
        if (IdCapture.instance.usesNFC) {
            BridgeLog.d("AmaniBridge", "[NFC] requesting MRZ from ID capture")
            IdCapture.instance.getMRZ(
                    onComplete = {
                        BridgeLog.d("AmaniBridge", "[NFC] MRZ received, hasBirthDate=${it.mRZBirthDate != null} hasExpiryDate=${it.mRZExpiryDate != null} hasDocumentNo=${it.mRZDocumentNumber != null}")
                        if (it.mRZBirthDate == null && it.mRZExpiryDate == null && it.mRZDocumentNumber == null) {
                            BridgeLog.e("AmaniBridge", "[NFC] MRZ values are empty")
                            activity.runOnUiThread {
                                channel.invokeMethod("onError", mapOf("message" to "mrz value wrong"))
                                result.success(false)
                            }
                            return@getMRZ
                        }

                        this.birthDate = it.mRZBirthDate
                        this.expireDate = it.mRZExpiryDate
                        this.documentNo = it.mRZDocumentNumber
                        this.activityRef = activity
                        // In API v2 this callback runs on the SDK's SSE reader thread.
                        // NfcAdapter calls must run on the main thread, and an exception
                        // thrown here would also break the SDK's SSE stream.
                        activity.runOnUiThread { startNFC(activity, result, channel) }
                    },
                    onError = {
                        BridgeLog.e("AmaniBridge", "[NFC] MRZ request failed: code=${it.errorCode} message=${it.errorMessage}")
                        // The iOS Part returns false when the MRZ request had failed.
                        activity.runOnUiThread { result.success(false) }
                    }
            )
        } else {
            this.birthDate = birthDate
            this.expireDate = expireDate
            this.documentNo = documentNo
            this.activityRef = activity
            activity.runOnUiThread { startNFC(activity, result, channel) }
        }
    }

    // Suppressed lint as we support compiler 33 and we're checking the version code
    @SuppressLint("WrongConstant")
    private fun startNFC(activity: Activity, result: MethodChannel.Result, channel: MethodChannel) {
        try {
            enableNFCReader(activity, result, channel)
        } catch (e: Exception) {
            BridgeLog.e("AmaniBridge", "[NFC] failed to enable reader mode", e)
            result.error("30056", "Failed to start NFC reading: ${e.message}", null)
        }
    }

    @SuppressLint("WrongConstant")
    private fun enableNFCReader(activity: Activity, result: MethodChannel.Result, channel: MethodChannel) {
        nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
        BridgeLog.d("AmaniBridge", "[NFC] adapter found=${nfcAdapter != null} enabled=${nfcAdapter?.isEnabled}")
        if (nfcAdapter != null) {
            // Drop a reader session left over from an earlier attempt, so the card is
            // always read with this attempt's MRZ values.
            nfcAdapter!!.disableReaderMode(activity)
            // Reader mode alone delivers the tag. The former foreground dispatch pointed at this
            // helper class (not an Activity) through a mutable PendingIntent, which could never
            // deliver anything and only widened the attack surface.
            nfcAdapter!!.enableReaderMode(activity, {
                BridgeLog.d("AmaniBridge", "[NFC] tag discovered, starting read")
                activity.runOnUiThread {
                    channel.invokeMethod("onScanStart", mapOf("started" to true))
                }
                val bac = Triple(birthDate, expireDate, documentNo)
                val (bd, ed, dn) = bac
                if (bd == null || ed == null || dn == null) {
                    activity.runOnUiThread { channel.invokeMethod("onError", mapOf("message" to "MRZ values are missing")) }
                    return@enableReaderMode
                }
                NFCModule.start(it, activity.applicationContext, bd, ed, dn) { _: Bitmap?, isSuccess: Boolean, exception: String? ->
                    BridgeLog.d("AmaniBridge", "[NFC] read finished isSuccess=$isSuccess exception=$exception")
                    if (isSuccess && exception == null) {
                        // Stop listening once the card is read; a new attempt enables it again.
                        activity.runOnUiThread { nfcAdapter?.disableReaderMode(activity) }
                        // The MRZ values are personal data; do not keep them past the read.
                        clearMrz()
                    }
                    if(isSuccess && exception == null) {
                        channel.invokeMethod("onNFCCompleted", mapOf("isSuccess" to isSuccess))
                    } else {
                        channel.invokeMethod("onError", mapOf("message" to (exception ?: "NFC read failed")))
                    }
                }
            }, NfcAdapter.FLAG_READER_NFC_A, null)

            BridgeLog.d("AmaniBridge", "[NFC] reader mode enabled, waiting for card")
            result.success(true)
        } else {
            result.error("30006", "Failed to get default nfc adapter", null)
        }
    }

    private fun clearMrz() {
        birthDate = null
        expireDate = null
        documentNo = null
    }

    fun disableNFC(activity: FlutterFragmentActivity) {
        nfcAdapter?.disableReaderMode(activity)
        clearMrz()
        BridgeLog.d("AmaniBridge", "[NFC] reader mode disabled")
    }

    fun setType(type: String, result: MethodChannel.Result) {
        docType = type
        result.success(null)
    }

    fun upload(result: MethodChannel.Result) {
        try {

            val fa = activityRef as? FragmentActivity
                ?: run { result.error("30020", "Activity must be FragmentActivity", null); return }
            Amani.sharedInstance().ScanNFC()
                .upload(fa, docType) {
                    result.success(it)
                }
        } catch (e: Exception) {
            result.error("30012", "Upload exception", e.message)
        }
    }

    /** Uploads the NFC data and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun upload(result: MethodChannel.Result, returnDocumentId: Boolean) {
        if (!returnDocumentId) { upload(result); return }
        try {
            val fa = activityRef as? FragmentActivity
                ?: run { result.uploadResultFailure("NFC", "Activity must be FragmentActivity"); return }
            Amani.sharedInstance().ScanNFC()
                .upload(fa, docType, result.uploadResultCallBack("NFC"))
        } catch (e: Exception) {
            result.uploadResultFailure("NFC", e.message)
        }
    }

}