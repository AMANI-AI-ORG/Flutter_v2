
package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.sdk.Amani
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

class Selfie: Module {
    private val selfieModule = Amani.sharedInstance().Selfie()

    //  String? -> String 
    private var docType: String = "XXX_SE_0"

    private var frag: Fragment? = null
    private var closeButton: Button? = null

    companion object {
        val instance = Selfie()
    }

    override fun start(stepID: Int, activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        val id = 0x123456
        val viewParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

      
        val container = FrameLayout(fa)
        container.id = id
        fa.addContentView(container, viewParams)

        frag = selfieModule.start(docType) { bitmap, _, _ ->
            if (bitmap != null) {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream)
                result.success(stream.toByteArray())

                fa.supportFragmentManager.beginTransaction()
                    .remove(frag!!)
                    .commitAllowingStateLoss()

                fa.runOnUiThread { closeButton?.visibility = View.GONE }
                frag = null
            }
        }

        closeButton = container.setupBackButton(R.drawable.baseline_close_24, onClick = {
            frag?.let {
                fa.supportFragmentManager.beginTransaction().remove(it).commitAllowingStateLoss()
                frag = null
            }
        })

        frag?.let {
            fa.supportFragmentManager.beginTransaction()
                .replace(id, it)
                .commitAllowingStateLoss()
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

    override fun upload(activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }

        try {
            // Dokümana uygun: upload(context, docType) { ... } :contentReference[oaicite:6]{index=6}
            selfieModule.upload(fa, docType) {
                result.success(it)
            }
        } catch (e: Exception) {
            result.error("30012", "Upload exception", e.message)
        }
    }

    /** Uploads the selfie and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }
        try {
            selfieModule.upload(fa, docType, result.uploadResultCallBack("Selfie"))
        } catch (e: Exception) {
            result.uploadResultFailure("Selfie", e.message)
        }
    }

    override fun setType(type: String?, result: MethodChannel.Result) {
        this.docType = type ?: this.docType
        result.success(null)
    }
}
