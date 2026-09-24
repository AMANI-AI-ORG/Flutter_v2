package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.sdk.Amani
import ai.amani.sdk.modules.signature.interfaces.ISignatureStartCallBack
import ai.amani.sdk.modules.signature.view.SignatureFragment
import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Flutter bridge for the Android SDK's Signature module.
 *
 * The SDK only provides the drawing canvas, so this class builds the screen around it:
 * a title, a counter for multi-signature flows, and Clear / Confirm / Close buttons.
 * The controls sit above and below the canvas, so they never appear in the signature image.
 */
class SignatureCapture {
    private val signatureModule = Amani.sharedInstance().Signature()

    private var container: View? = null
    private var frag: Fragment? = null
    private var counterView: TextView? = null
    private var pendingResult: MethodChannel.Result? = null
    private var total = 1

    companion object {
        val instance = SignatureCapture()
    }

    fun start(arguments: Map<String, Any?>?, activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }
        val settings = SignatureSettings(arguments)

        fa.runOnUiThread {
            dismiss(fa)
            total = settings.count
            pendingResult = result

            // The SDK keeps its signature count between sessions, so start from zero.
            signatureModule.resetCountOfSignature()

            val hostId = View.generateViewId()
            val root = buildLayout(fa, settings, hostId)
            fa.addContentView(
                root,
                FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
            )
            container = root

            val fragment = signatureModule.start(fa, settings.count, object : ISignatureStartCallBack {
                override fun cb(bitmap: Bitmap?, count: Int) {
                    fa.runOnUiThread { onSignatureConfirmed(fa, bitmap, count) }
                }
            })
            frag = fragment
            fa.supportFragmentManager.beginTransaction()
                .replace(hostId, fragment)
                .commitAllowingStateLoss()

            updateCounter(0)
            Log.d("AmaniBridge", "[Signature] started, expecting ${settings.count} signature(s)")
        }
    }

    fun upload(result: MethodChannel.Result) {
        try {
            signatureModule.upload { isSuccess -> result.success(isSuccess) }
        } catch (e: Exception) {
            result.error("30012", "Upload exception", e.message)
        }
    }

    /** Uploads the confirmed signatures and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(result: MethodChannel.Result) {
        try {
            signatureModule.upload(result.uploadResultCallBack("Signature"))
        } catch (e: Exception) {
            result.uploadResultFailure("Signature", e.message)
        }
    }

    fun backPressHandle(activity: Activity, result: MethodChannel.Result) {
        val fa = activity as? FragmentActivity
            ?: run {
                result.error("30020", "Activity must be FragmentActivity", null)
                return
            }
        if (container == null) {
            result.error(
                "30001",
                "You must call this function while the module is running",
                "You can ignore this message and return true from onWillPop()"
            )
            return
        }
        fa.runOnUiThread {
            cancel(fa)
            result.success(false)
        }
    }

    // region Flow

    private fun onSignatureConfirmed(fa: FragmentActivity, bitmap: Bitmap?, count: Int) {
        if (bitmap == null) {
            // The SDK reports an empty canvas with a null bitmap; wait for a real signature.
            Log.d("AmaniBridge", "[Signature] confirm pressed on an empty canvas")
            return
        }
        Log.d("AmaniBridge", "[Signature] signature $count of $total confirmed")
        updateCounter(count)
        if (count < total) return

        val result = pendingResult ?: return
        pendingResult = null
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        result.success(stream.toByteArray())
        dismiss(fa)
    }

    private fun cancel(fa: FragmentActivity) {
        Log.d("AmaniBridge", "[Signature] cancelled by the user")
        val result = pendingResult
        pendingResult = null
        dismiss(fa)
        result?.error("30053", "Signature capture was cancelled by the user.", null)
    }

    private fun dismiss(fa: FragmentActivity) {
        frag?.let {
            fa.supportFragmentManager.beginTransaction().remove(it).commitAllowingStateLoss()
        }
        frag = null
        container?.let { (it.parent as? ViewGroup)?.removeView(it) }
        container = null
        counterView = null
    }

    private fun updateCounter(completed: Int) {
        counterView?.apply {
            visibility = if (total <= 1) View.GONE else View.VISIBLE
            text = "${minOf(completed + 1, total)} / $total"
        }
    }

    // endregion

    // region Layout

    private fun buildLayout(fa: FragmentActivity, settings: SignatureSettings, hostId: Int): View {
        fun dp(value: Int) = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), fa.resources.displayMetrics
        ).toInt()

        val root = LinearLayout(fa).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            isClickable = true // keep touches away from the Flutter view underneath
            setPadding(0, statusBarHeight(fa), 0, dp(16))
        }

        // Header: title + counter, close button on the right
        val header = FrameLayout(fa)
        val titles = LinearLayout(fa).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(56), dp(16), dp(56), dp(8))
        }
        titles.addView(TextView(fa).apply {
            text = settings.title
            setTextColor(Color.DKGRAY)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })
        val counter = TextView(fa).apply {
            setTextColor(Color.GRAY)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
            setPadding(0, dp(6), 0, 0)
        }
        counterView = counter
        titles.addView(counter)
        header.addView(titles, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        header.addView(ImageButton(fa).apply {
            setImageResource(R.drawable.baseline_close_24)
            setColorFilter(Color.DKGRAY)
            background = null
            setOnClickListener { cancel(fa) }
        }, FrameLayout.LayoutParams(dp(48), dp(48), Gravity.END or Gravity.TOP).apply {
            setMargins(0, dp(8), dp(8), 0)
        })
        root.addView(header)

        // SDK signature canvas
        root.addView(FrameLayout(fa).apply { id = hostId },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))

        // Buttons
        val buttons = LinearLayout(fa).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(16), dp(12), dp(16), 0)
        }
        buttons.addView(makeButton(fa, settings.clearButtonText, filled = false, color = settings.buttonColor, radius = dp(10)) {
            (frag as? SignatureFragment)?.cleanDigitalSignatureAtView()
        }, LinearLayout.LayoutParams(0, dp(50), 1f).apply { marginEnd = dp(6) })
        buttons.addView(makeButton(fa, settings.confirmButtonText, filled = true, color = settings.buttonColor, radius = dp(10)) {
            signatureModule.confirm(fa)
        }, LinearLayout.LayoutParams(0, dp(50), 1f).apply { marginStart = dp(6) })
        root.addView(buttons)

        return root
    }

    private fun makeButton(
        fa: FragmentActivity,
        title: String,
        filled: Boolean,
        color: Int,
        radius: Int,
        onClick: () -> Unit
    ): Button = Button(fa).apply {
        text = title
        isAllCaps = false
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
        setTextColor(if (filled) Color.WHITE else color)
        stateListAnimator = null
        background = GradientDrawable().apply {
            cornerRadius = radius.toFloat()
            setColor(if (filled) color else Color.WHITE)
            if (!filled) setStroke(3, color)
        }
        setOnClickListener { onClick() }
    }

    private fun statusBarHeight(fa: FragmentActivity): Int {
        val id = fa.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (id > 0) fa.resources.getDimensionPixelSize(id) else 0
    }

    // endregion

    private class SignatureSettings(arguments: Map<String, Any?>?) {
        val count: Int = maxOf(1, (arguments?.get("count") as? Int) ?: 1)
        val title: String = arguments?.get("title") as? String ?: "Please sign in the area below"
        val clearButtonText: String = arguments?.get("clearButtonText") as? String ?: "Clear"
        val confirmButtonText: String = arguments?.get("confirmButtonText") as? String ?: "Confirm"
        val buttonColor: Int = parseColor(arguments?.get("buttonColor") as? String)

        private fun parseColor(hex: String?): Int =
            try {
                if (hex.isNullOrBlank()) DEFAULT_COLOR else Color.parseColor(if (hex.startsWith("#")) hex else "#$hex")
            } catch (e: IllegalArgumentException) {
                DEFAULT_COLOR
            }

        companion object {
            private val DEFAULT_COLOR = Color.parseColor("#1E88E5")
        }
    }
}
