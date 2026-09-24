package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.flutter_amanisdk.modules.config_models.PoseEstimationSettings
import ai.amani.sdk.Amani
import ai.amani.sdk.modules.selfie.pose_estimation.observable.OnFailurePoseEstimation
import ai.amani.sdk.modules.selfie.pose_estimation.observable.PoseEstimationObserver
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
import java.lang.Exception

class PoseEstimation: Module {
    private val poseEstimationModule = Amani.sharedInstance().SelfiePoseEstimation()
    private var docType: String = "XXX_SE_0"
    private var frag: Fragment? = null
    var closeButton: Button? = null
    private var settings: PoseEstimationSettings? = null
    private var videoRecordEnabled = false

    companion object {
        val instance = PoseEstimation()
    }

    override fun start(stepID: Int, activity: Activity, result: MethodChannel.Result) {

        if (settings == null) {
            result.error("30003", "Settings not set", null)
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

        val observer: PoseEstimationObserver = object : PoseEstimationObserver {
            override fun onError(error: Error) {
                (activity as FragmentActivity).supportFragmentManager.
                beginTransaction().remove(frag!!).commit()

                activity.runOnUiThread {
                    closeButton!!.visibility = View.GONE
                }

                result.error("30006", error.message, null)
            }

            override fun onFailure(reason: OnFailurePoseEstimation, currentAttempt: Int) {

            }

            override fun onSuccess(bitmap: Bitmap?) {
                if (bitmap != null) {
                   val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                    result.success(stream.toByteArray())

                    activity.runOnUiThread {
                        closeButton!!.visibility = View.GONE
                    }

                    (activity as FragmentActivity).removeFragment(frag)

                    frag = null
                }
            }
        }

        frag = poseEstimationModule
                .Builder()
       .userInterfaceTexts(
           settings!!.faceIsTooFar,
           settings!!.faceNotStraight,
           settings!!.faceNotInside,
           settings!!.holdPhoneVertically,
           settings!!.alertTitle,
           settings!!.alertDescription,
           settings!!.alertTryAgain,
           settings!!.turnLeft,
           settings!!.turnRight,
           settings!!.turnUp,
           settings!!.turnDown,
           settings!!.lookStraight
        ).userInterfaceColors(
                ovalViewStartColor = R.color.pose_estimation_oval_view_start,
                ovalViewSuccessColor = R.color.pose_estimation_oval_view_success,
                ovalViewErrorColor =  R.color.pose_estimation_oval_view_error,
                alertTitleFontColor = R.color.pose_estimation_alert_title,
                alertDescriptionFontColor = R.color.pose_estimation_alert_description,
                alertTryAgainFontColor = R.color.pose_estimation_alert_try_again,
                alertBackgroundFontColor = R.color.pose_estimation_alert_background,
                appFontColor =  R.color.pose_estimation_font
        ).userInterfaceVisibilities(
                settings!!.mainGuideVisibility,
                settings!!.secondaryGuideVisibility
        ).userInterfaceDrawables(
                        R.drawable.pose_esitmation_main_guide_left,
                        R.drawable.pose_estimation_main_guide_right,
                        R.drawable.pose_estimation_main_guide_up,
                        R.drawable.pose_estimation_main_guide_down,
                        R.drawable.pose_estimation_main_guide_straight,
                        R.drawable.pose_estimation_secondary_guide_left,
                        R.drawable.pose_estimation_secondary_guide_right,
                        R.drawable.pose_estimation_secondary_guide_up,
                        R.drawable.pose_estimation_secondary_guide_down,
        )
        .ovalViewAnimationDurationMilSec(settings!!.animationDuration)
        .requestedPoseNumber(settings!!.poseCount)
        .videoRecord(this.videoRecordEnabled)
        .observe(observer).build(activity)

        (activity as FragmentActivity)
        val id = 0x123456
        val context = activity.applicationContext
        val viewParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        val container = FrameLayout(context)
        container.id = id
        activity.addContentView(container, viewParams)

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
            poseEstimationModule.upload((activity as FragmentActivity), docType) {
                result.success(it)
            }} catch (e: Exception) {
            result.error("30012", "Upload exception", e.message)
        }
    }

    /** Uploads the pose estimation selfie and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(activity: Activity, result: MethodChannel.Result) {
        try {
            poseEstimationModule.upload(activity as FragmentActivity, docType, result.uploadResultCallBack("PoseEstimation"))
        } catch (e: Exception) {
            result.uploadResultFailure("PoseEstimation", e.message)
        }
    }

    override fun setType(type: String?, result: MethodChannel.Result) {
        if (type != null) {
            this.docType = type
            result.success(null)
        }
    }

    fun setSettings(poseEstimationSettings: PoseEstimationSettings) {
        this.settings = poseEstimationSettings
    }

    fun setVideoRecording(enabled: Boolean, result: MethodChannel.Result) {
        videoRecordEnabled = enabled
        result.success(null)
    }
}