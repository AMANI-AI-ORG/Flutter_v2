package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.sdk.Amani
import ai.amani.sdk.model.amani_events.error.AmaniError
import ai.amani.sdk.model.mrz.MRZResult
import android.app.Activity
import android.graphics.Bitmap
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.flutter.Log
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.lang.Exception


class IdCapture : Module {
    private var idCaptureModule = Amani.sharedInstance().IDCapture()
    private var docType: String? = null
    private var frag: Fragment? = null
    var usesNFC = false
    var closeButton: Button? = null

    companion object {
        val instance = IdCapture()
    }
    override fun start(stepID: Int, activity: Activity, result: Result) {
        if(docType == null) {
            result.error("30003", "Type not set.", "You have to call setType on idCapture before calling this method.")
            return
        }

        if (frag != null) {
            result.error(
                "30021",
                "Start function is already triggered before",
                "You cannot call start function before previous session is end up."
            )
            return
        }

        val side: Boolean = stepID == 0

        (activity as FragmentActivity)
        val id = 0x123456
        val context = activity.applicationContext
        val viewParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        val container = FrameLayout(context)
        container.id = id
        activity.addContentView(container, viewParams)

        frag = idCaptureModule.start(activity, container, docType!!, side) { bitmap, _, _ ->
            if (bitmap != null) {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                activity.runOnUiThread {
                    closeButton!!.visibility = View.GONE
                }

                result.success(stream.toByteArray())
                activity.removeFragment(frag)
                frag = null
            }
        }

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            activity.removeFragment(frag)
            frag = null
        })

        if (frag == null) {
            result.error("30005", "Failed to initialize ID Capture", null)
            return
        }

        activity.replaceFragment(
            containerViewId = id,
            fragment = frag
        )
    }

    fun setWithNFC(usesNFC: Boolean = false) {
        this.usesNFC = usesNFC
        idCaptureModule.withNFC(usesNFC)
    }

    fun setManualCaptureButtonTimeout(timeout: Int) {
        idCaptureModule.setManualCropTimeOut(timeout);
    }

    fun getMRZ(onComplete: (MRZResult) -> Unit,  onError: (AmaniError) -> Unit  ) {
        Amani.sharedInstance().IDCapture().getMRZ(type = docType!!, onComplete = onComplete, onError = onError)
    }

    fun backPressHandle(activity: Activity, result: Result) {
        if (frag == null){
            result.error("30001",
                    "You must call this function while the" +
                    "module is running", "You can ignore this message and return true" +
                    "from onWillPop()")
        } else {
            activity.runOnUiThread {
                frag?.let {
                    closeButton!!.visibility = View.GONE
                    it.parentFragmentManager.beginTransaction().remove(frag!!).commit()
                    frag = null
                    // This blocks the flutters back press action.
                    result.success(false)
                }
            }
        }
    }

    override fun upload(activity: Activity, result : Result) {
        if (docType.isNullOrEmpty()) {
            result.error("30003", "Type not set.", "You have to call setType on idCapture before calling this method.")
        }
        try {
            idCaptureModule.upload((activity as FragmentActivity), docType!!) {
                result.success(it)
            }} catch (e: Exception) {
            result.error("30012", "Upload exception", e.message)
        }
    }

    /** Uploads the captured ID and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(activity: Activity, result: Result) {
        val type = docType
        if (type.isNullOrEmpty()) {
            result.error("30003", "Type not set.", "You have to call setType on idCapture before calling this method.")
            return
        }
        try {
            idCaptureModule.upload(activity as FragmentActivity, type, result.uploadResultCallBack("IDCapture"))
        } catch (e: Exception) {
            result.uploadResultFailure("IDCapture", e.message)
        }
    }

    override fun setType(type: String?, result: Result) {
        this.docType = type
        Log.d("AmaniSDK", "setTypeCalled!")
        result.success(null)
    }

    fun setHologramDetection(enabled: Boolean, result: Result) {
        idCaptureModule.hologramDetection(enabled)
        result.success(null)
    }

    fun setVideoRecording(enabled: Boolean, result: Result) {
        idCaptureModule.videoRecord(enabled)
        result.success(null)
    }

}