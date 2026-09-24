package ai.amani.flutter_amanisdk.modules

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel

import ai.amani.speechverifier.SpeechVerifier
import ai.amani.speechverifier.model.IdentityQuestionType
import ai.amani.speechverifier.model.VerificationStep
import ai.amani.speechverifier.model.SpeechVerifierUploadError
import ai.amani.speechverifier.model.SpeechVerifierUploadResult
import ai.amani.speechverifier.observable.OnFailureSpeechVerifier
import ai.amani.speechverifier.observable.SpeechVerifierObserver
import ai.amani.speechverifier.observable.SpeechVerifierUploadObserver

import org.json.JSONObject

class SpeechVerifierModule(
    private val activity: Activity,
) {
    private var container: FrameLayout? = null
    private var startResult: MethodChannel.Result? = null
    private var didReturnStart = false

    private val containerViewId = View.generateViewId()

    fun start(settingsJson: String, result: MethodChannel.Result) {
        val fragmentActivity = activity as? FragmentActivity ?: run {
            result.error(
                "30040",
                "Host activity is not a FragmentActivity",
                null,
            )
            return
        }

        this.startResult = result
        this.didReturnStart = false

        val settings = try {
            JSONObject(settingsJson)
        } catch (e: Exception) {
            result.error("30031", "Invalid speech verifier settings: ${e.message}", null)
            return
        }

        val builder = SpeechVerifier.Builder()
            .documentType(settings.optString("type", "XXX_ST_0"))

        // Session (serverURL + token) — required for upload & identity fetch.
        val serverURL = settings.optStringOrNull("serverURL")
        val token = settings.optStringOrNull("token")
        if (serverURL != null && token != null) {
            builder.session(serverURL = serverURL, token = token)
        }

        // Steps: ordered mix of spokenText / identityQuestion.
        val steps = buildVerificationSteps(settings.optJSONArray("steps"))
        if (steps.isNotEmpty()) {
            builder.verificationSteps(steps)
        }

        // Identity answers supplied up-front (optional).
        settings.optJSONObject("identityAnswers")?.let { answers ->
            builder.identityAnswers(
                idNumber = answers.optStringOrNull("idNumber"),
                motherName = answers.optStringOrNull("motherName"),
                fatherName = answers.optStringOrNull("fatherName"),
                documentNumber = answers.optStringOrNull("documentNumber"),
            )
        }

        // Tunables.
        builder
            .autoDetectForeignWords(settings.optBoolean("autoDetectForeignWords", true))
            .detectTurkishNegation(settings.optBoolean("detectTurkishNegation", true))
            .ignoreTurkishDiacritics(settings.optBoolean("ignoreTurkishDiacritics", false))
            .timeoutMillis(settings.optLong("timeoutMillis", 60_000L))
            .bottomSheetCornerRadius(
            settings.optDouble("bottomSheetCornerRadius", 0.0).toFloat()
    )

        settings.optStringArray("rejectWords")?.let { builder.rejectWords(it) }
        settings.optStringArray("verificationExemptWords")?.let {
            builder.verificationExemptWords(it)
        }

        builder.observe(object : SpeechVerifierObserver {
            override fun onPreparing() { /* optionally surface via event channel */ }
            override fun onReady() { /* optionally surface via event channel */ }

            override fun onSuccess() {
                if (!didReturnStart) {
                    didReturnStart = true
                    // Android tracks the recording internally → no bytes to return.
                    startResult?.success(null)
                    startResult = null
                }
                removeFragment()
            }

            override fun onFailure(reason: OnFailureSpeechVerifier, currentAttempt: Int) {
                // Keep the screen up for retry; the module shows its own retry UI.
                // Optionally surface via the delegate/event channel.
            }

            override fun onError(error: Error) {
                if (!didReturnStart) {
                    didReturnStart = true
                    startResult?.error("30041", error.message ?: "Speech verifier error", null)
                    startResult = null
                }
                removeFragment()
            }
        })

        val fragment = try {
            builder.build()
        } catch (e: Exception) {
            result.error("30032", "Failed to build speech verifier: ${e.message}", null)
            return
        }

        // Create a full-screen container over the current activity and host the fragment.
        val root = fragmentActivity.window.decorView as ViewGroup
        val frame = FrameLayout(fragmentActivity).apply {
            id = containerViewId
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
        }
        root.addView(frame)
        container = frame

        fragmentActivity.supportFragmentManager
            .beginTransaction()
            .replace(containerViewId, fragment)
            .commitAllowingStateLoss()
    }

    fun upload(result: MethodChannel.Result) {
        SpeechVerifier.upload(
            context = activity,
            observer = object : SpeechVerifierUploadObserver {
                override fun onResult(uploadResult: SpeechVerifierUploadResult) {
                    result.success(true)
                }

                override fun onError(error: SpeechVerifierUploadError, message: String) {
                    result.success(false)
                }
            },
        )
    }

    /** Uploads the speech verification and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(result: MethodChannel.Result) {
        SpeechVerifier.upload(
            context = activity,
            observer = object : SpeechVerifierUploadObserver {
                override fun onResult(uploadResult: SpeechVerifierUploadResult) {
                    result.success(mapOf("isSuccess" to true, "documentId" to uploadResult.documentId))
                }

                override fun onError(error: SpeechVerifierUploadError, message: String) {
                    result.success(mapOf("isSuccess" to false, "documentId" to null))
                }
            },
        )
    }

    private fun buildVerificationSteps(array: org.json.JSONArray?): List<VerificationStep> {
        if (array == null) return emptyList()
        val steps = mutableListOf<VerificationStep>()

        for (i in 0 until array.length()) {
            val step = array.optJSONObject(i) ?: continue
            when (step.optString("type")) {
                "spokenText" -> {
                    val items = step.optJSONArray("items") ?: continue
                    val texts = (0 until items.length())
                        .mapNotNull { items.optJSONObject(it)?.optStringOrNull("text") }
                    if (texts.isNotEmpty()) {
                        steps.add(VerificationStep.SpokenText.of(*texts.toTypedArray()))
                    }
                }
                "identityQuestion" -> {
                    val items = step.optJSONArray("items") ?: continue
                    val types = (0 until items.length()).mapNotNull {
                        mapQuestionType(items.optJSONObject(it)?.optString("type"))
                    }
                    if (types.isNotEmpty()) {
                        steps.add(VerificationStep.IdentityQuestion.of(*types.toTypedArray()))
                    }
                }
            }
        }
        return steps
    }

    private fun mapQuestionType(raw: String?): IdentityQuestionType? = when (raw) {
        "idNumber" -> IdentityQuestionType.ID_NUMBER
        "motherName" -> IdentityQuestionType.MOTHER_NAME
        "fatherName" -> IdentityQuestionType.FATHER_NAME
        "documentNumber" -> IdentityQuestionType.DOCUMENT_NUMBER
        else -> null
    }

    fun handleBackPress(): Boolean {
        return if (container != null) {
            removeFragment()
            false
        } else {
            true
        }
    }

    private fun removeFragment() {
        container?.let { frame ->
            (frame.parent as? ViewGroup)?.removeView(frame)
        }
        container = null
    }
}

// ── JSON helpers ──────────────────────────────────────────────────────────

private fun JSONObject.optStringOrNull(key: String): String? {
    if (!has(key) || isNull(key)) return null
    val value = optString(key)
    return value.ifBlank { null }
}

private fun JSONObject.optStringArray(key: String): List<String>? {
    val array = optJSONArray(key) ?: return null
    val list = (0 until array.length()).mapNotNull { array.optString(it).ifBlank { null } }
    return list.ifEmpty { null }
}