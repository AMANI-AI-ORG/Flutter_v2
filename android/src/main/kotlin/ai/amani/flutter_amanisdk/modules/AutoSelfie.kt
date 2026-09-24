package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.flutter_amanisdk.modules.config_models.AutoSelfieSettings
import ai.amani.sdk.Amani
import ai.amani.sdk.modules.selfie.auto_capture.ASCBuilder
import android.app.Activity
import android.graphics.Bitmap
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class AutoSelfie: Module {
    private val autoSelfieModule = Amani.sharedInstance().AutoSelfieCapture()
    private var docType: String = "XXX_SE_0"
    private var frag: Fragment? = null
    private var closeButton: Button? = null
    private var settings: AutoSelfieSettings? = null

    companion object {
        val instance = AutoSelfie()
    }

    override fun start(stepID: Int, activity: Activity, result: MethodChannel.Result) {

        if(settings == null) {
            result.error("30003", "Settings not set", "You have to call setSettings before calling this method.")
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

        (activity as FragmentActivity)
        val id = 0x123456
        val context = activity.applicationContext
        val viewParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        val container = FrameLayout(context)
        container.id = id
        activity.addContentView(container, viewParams)

        val ascBuilder = ASCBuilder(
            R.color.auto_selfie_text,
                settings!!.textSize,
                R.color.auto_selfie_counter_text,
                settings!!.counterVisible,
                settings!!.counterTextSize,
                settings!!.manualCaptureTimeout,
                settings!!.distanceText,
                settings!!.faceNotFoundText,
                settings!!.stableText,
                settings!!.restartText,
                R.color.auto_selfie_oval_view,
                R.color.auto_selfie_success_anim,
        )


        frag = autoSelfieModule.start(docType, ascBuilder, container) { bitmap, _, file ->
            if (bitmap != null) {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                result.success(stream.toByteArray())

                activity.removeFragment(frag)

                activity.runOnUiThread {
                    closeButton!!.visibility = View.GONE
                }

            }
        }

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            activity.removeFragment(frag)
            frag = null
        })

        activity.replaceFragment(
            containerViewId = id,
            fragment = frag
        )
    }

    fun backPressHandle(activity: Activity, result: MethodChannel.Result) {
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

    override fun upload(activity: Activity, result: MethodChannel.Result) {
        try {
            autoSelfieModule.upload((activity as FragmentActivity), docType) {
                result.success(it)
            }} catch (e: Exception) {
                result.error("30012", "Upload exception", e.message)
            }
    }

    /** Uploads the auto selfie and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(activity: Activity, result: MethodChannel.Result) {
        try {
            autoSelfieModule.upload(activity as FragmentActivity, docType, result.uploadResultCallBack("AutoSelfie"))
        } catch (e: Exception) {
            result.uploadResultFailure("AutoSelfie", e.message)
        }
    }

    override fun setType(type: String?, result: MethodChannel.Result) {
        if (type != null) {
            this.docType = type
            result.success(null)
        }
    }

    fun setSettings(settings: AutoSelfieSettings) {
        this.settings = settings
    }
}