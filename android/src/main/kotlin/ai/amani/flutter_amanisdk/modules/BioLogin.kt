
package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.flutter_amanisdk.modules.config_models.AutoSelfieSettings
import ai.amani.flutter_amanisdk.modules.config_models.PoseEstimationSettings
import ai.amani.sdk.Amani
import ai.amani.sdk.interfaces.AutoSelfieCaptureObserver
import ai.amani.sdk.interfaces.BioLoginUploadCallBack
import ai.amani.sdk.interfaces.bioLoginUploadCallBack
import ai.amani.sdk.interfaces.ManualSelfieCaptureObserver
import ai.amani.sdk.modules.selfie.pose_estimation.observable.OnFailurePoseEstimation
import ai.amani.sdk.modules.selfie.pose_estimation.observable.PoseEstimationObserver
import android.app.Activity
import android.content.Context //  FIX: Context import
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.atomic.AtomicBoolean

class BioLogin {
    private var docType: String = "XXX_SE_0"
    private var frag: Fragment? = null

    // keep context for upload
    private var appContext: Context? = null

    private var comparisonAdapter: Int = 2
    private var source: Int = 3
    private var attemptID: String? = null
    private var closeButton: Button? = null

    companion object  {
        val instance = BioLogin()
    }

    fun initBioLogin(
        server: String,
        sharedSecret: String?,
        token: String,
        comparisonAdapter: Int?,
        source: Int?,
        attemptID: String?,
        activity: Activity,
        result: MethodChannel.Result
    ) {
       
        // BioLogin V2 runs on the session started with Amani.configure() +
        // startSession() (setConfigure + startAmaniSDKWithConfigure in Flutter).
        // Amani.initBio() is not part of the V2 flow: it re-initializes the
        // network client and can override the configured session, so it is not
        // called here. server, token and sharedSecret are kept for API
        // compatibility; the session's own values are used.
        Log.d("AmaniBridge", "[BioLogin] init: using the SDK session started with configure + startSession")

        this.appContext = activity.applicationContext

        if (comparisonAdapter != null) this.comparisonAdapter = comparisonAdapter
        if (source != null) this.source = source
        this.attemptID = attemptID

        result.success(null)
    }

    fun startWithAutoSelfie(settings: AutoSelfieSettings, activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        appContext = fa.applicationContext

        val id = 0x123456
        val viewParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        val container = FrameLayout(fa)
        container.id = id
        fa.addContentView(container, viewParams)

        frag = Amani.sharedInstance().BioLogin().AutoSelfieCapture()
            .documentType(docType)
            .timeOutManualButton(settings.manualCaptureTimeout)
            .userInterfaceColors(
                ovalViewStartColor = R.color.auto_selfie_oval_view,
                ovalViewSuccessColor = R.color.auto_selfie_success_anim,
                appFontColor = R.color.auto_selfie_text,
                manualButtonColor = R.color.auto_selfie_counter_text,
            )
            .userInterfaceTexts(
                faceIsTooFarText = settings.distanceText,
                holdStableText = settings.stableText,
                faceNotFoundText = settings.faceNotFoundText,
            )
            //  FIX: configuration() removed 
            .observer(object : AutoSelfieCaptureObserver {
                override fun cb(bitmap: Bitmap?) {
                    bitmap?.let {
                        val stream = ByteArrayOutputStream()
                        it.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                        result.success(stream.toByteArray())
                    }

                    closeButton?.visibility = View.GONE
                    frag?.let { f ->
                        fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
                    }
                    frag = null
                }
            })
            .build()

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            frag?.let { f ->
                fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
            }
            frag = null
        })

        frag?.let {
            fa.supportFragmentManager.beginTransaction()
                .replace(id, it)
                .commitAllowingStateLoss()
        }
    }

    fun startWithPoseEstimation(settings: PoseEstimationSettings, activity: Activity, result: MethodChannel.Result, channel: MethodChannel) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        appContext = fa.applicationContext

        val id = 0x123456
        val viewParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        val container = FrameLayout(fa)
        container.id = id
        fa.addContentView(container, viewParams)

        frag = Amani.sharedInstance().BioLogin().PoseEstimation()
            .documentType(docType)
            .requestedPoseNumber(settings.poseCount)
            .ovalViewAnimationDurationMilSec(settings.animationDuration)
            //   FIX: configuration() removed
            .userInterfaceColors(
                ovalViewStartColor = R.color.pose_estimation_oval_view_start,
                ovalViewSuccessColor = R.color.pose_estimation_oval_view_success,
                ovalViewErrorColor =  R.color.pose_estimation_oval_view_error,
                alertTitleFontColor = R.color.pose_estimation_alert_title,
                alertDescriptionFontColor = R.color.pose_estimation_alert_description,
                alertTryAgainFontColor = R.color.pose_estimation_alert_try_again,
                alertBackgroundFontColor = R.color.pose_estimation_alert_background,
                appFontColor =  R.color.pose_estimation_font,
            )
            .userInterfaceVisibilities(
                settings.mainGuideVisibility,
                settings.secondaryGuideVisibility
            )
            .userInterfaceDrawables(
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
            .userInterfaceTexts(
                settings.faceNotInside,
                settings.faceNotStraight,
                settings.faceIsTooFar,
                settings.holdPhoneVertically,
                settings.alertTitle,
                settings.alertDescription,
                settings.alertTryAgain
            )
            .observer(object: PoseEstimationObserver {
                override fun onError(error: Error) {
                    channel.invokeMethod("androidBioLoginPoseEstimation#onError", mapOf("message" to error.message))
                }

                override fun onFailure(reason: OnFailurePoseEstimation, currentAttempt: Int) {
                    channel.invokeMethod(
                        "androidBioLoginPoseEstimation#onFailure",
                        mapOf("reason" to reason.name, "currentAttempt" to currentAttempt)
                    )
                }

                override fun onSuccess(bitmap: Bitmap?) {
                    bitmap?.let {
                        val stream = ByteArrayOutputStream()
                        it.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                        channel.invokeMethod(
                            "androidBioLoginPoseEstimation#onSuccess",
                            mapOf("image" to stream.toByteArray())
                        )
                    }

                    fa.runOnUiThread { closeButton?.visibility = View.GONE }
                    frag?.let { f ->
                        fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
                    }
                    frag = null
                }
            })
            .build()

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            frag?.let { f ->
                fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
            }
            frag = null
        })

        frag?.let {
            fa.supportFragmentManager.beginTransaction()
                .replace(id, it)
                .commitAllowingStateLoss()
        }
    }

    fun startWithManualSelfie(selfieDescriptionText: String, activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        appContext = fa.applicationContext

        val id = 0x123456
        val viewParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        val container = FrameLayout(fa)
        container.id = id
        fa.addContentView(container, viewParams)

        frag = Amani.sharedInstance().BioLogin().ManualSelfieCapture()
            .documentType(docType)
            .userInterfaceColors(
                appFontColor = R.color.biologin_manual_selfie_font,
                manualButtonColor = R.color.biologin_manual_selfie_button,
                ovalViewColor = R.color.biologin_manual_selfie_oval_view,
                appBackgroundColor = R.color.biologin_manual_selfie_background
            )
            .userInterfaceTexts(selfieDescriptionText = selfieDescriptionText)
            //   FIX: configuration() removed
            .observer(object : ManualSelfieCaptureObserver {
                override fun cb(bitmap: Bitmap?) {
                    bitmap?.let {
                        val stream = ByteArrayOutputStream()
                        it.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                        result.success(stream.toByteArray())
                    }

                    fa.runOnUiThread { closeButton?.visibility = View.GONE }
                    frag?.let { f ->
                        fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
                    }
                    frag = null
                }
            })
            .build()

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            frag?.let { f ->
                fa.supportFragmentManager.beginTransaction().remove(f).commitAllowingStateLoss()
            }
            frag = null
        })

        frag?.let {
            fa.supportFragmentManager.beginTransaction()
                .replace(id, it)
                .commitAllowingStateLoss()
        }
    }

    fun upload(completion: MethodChannel.Result) {
        val ctx = appContext
        if (ctx == null) {
            completion.error("30003", "Context is null. Start a BioLogin capture before upload.", null)
            return
        }

        // Compatible Upload func with doc
        Amani.sharedInstance().BioLogin().upload(ctx, object : BioLoginUploadCallBack {
            override fun cb(result: Boolean?) {
                if (result == true) completion.success(true)
                else completion.success(false)
            }
        })
    }

    /** Uploads the BioLogin selfie and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun upload(completion: MethodChannel.Result, returnDocumentId: Boolean) {
        if (!returnDocumentId) { upload(completion); return }
        val ctx = appContext
        if (ctx == null) {
            completion.error("30003", "Context is null. Start a BioLogin capture before upload.", null)
            return
        }

        val replied = AtomicBoolean(false)
        fun reply(isSuccess: Boolean?, documentId: String?) {
            if (!replied.compareAndSet(false, true)) return
            Log.d("AmaniBridge", "[BioLogin] upload result isSuccess=$isSuccess documentId=$documentId")
            val payload = mapOf("isSuccess" to (isSuccess == true), "documentId" to documentId)
            Handler(Looper.getMainLooper()).post { completion.success(payload) }
        }

        try {
            // Documented V2 helper: forwards both cb overloads, so documentID is
            // null when the upload fails or the backend returns no id.
            // For BioLogin, isSuccess means the selfie was approved, not only uploaded.
            Amani.sharedInstance().BioLogin().upload(ctx, bioLoginUploadCallBack { result, documentID ->
                reply(result, documentID)
            })
        } catch (e: Exception) {
            Log.e("AmaniBridge", "[BioLogin] upload failed", e)
            reply(false, null)
        }
    }

    fun backPressHandle(activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        val currentFrag = frag
        if (currentFrag == null) {
            result.error(
                "30001",
                "You must call this function while the module is running",
                "You can ignore this message and return true from onWillPop()"
            )
            return
        }

        fa.runOnUiThread {
            closeButton?.visibility = View.GONE
            currentFrag.parentFragmentManager.beginTransaction()
                .remove(currentFrag)
                .commitAllowingStateLoss()
            frag = null
            result.success(false)
        }
    }
}
