package ai.amani.flutter_amanisdk

import android.content.Context
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.util.Log

/**
 * Logging that stays silent in release builds of the host app.
 *
 * logcat is readable by anyone with adb access and, on older Android versions, by other
 * apps. Never pass tokens, secrets, MRZ values or document ids to these functions.
 */
internal object BridgeLog {
    @Volatile
    private var debuggable = false

    fun init(context: Context) {
        debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    fun d(tag: String, message: String) {
        if (debuggable) Log.d(tag, message)
    }

    fun w(tag: String, message: String, t: Throwable? = null) {
        if (debuggable) Log.w(tag, message, t)
    }

    fun e(tag: String, message: String, t: Throwable? = null) {
        // Only the throwable's class is logged in release: its message may carry request data.
        if (debuggable) Log.e(tag, message, t) else Log.e(tag, "$message (${t?.javaClass?.simpleName ?: "error"})")
    }
}

internal object BridgeSecurity {

    /**
     * Returns [server] when it is safe to talk to, otherwise null.
     *
     * Credentials and KYC data must never travel over cleartext HTTP, so only `https`
     * is accepted. `http` is tolerated for debuggable host apps only. A bare host with
     * no scheme is left to the Core SDK, which prepends https itself.
     */
    fun validatedServer(server: String?, allowCleartext: Boolean): String? {
        val raw = server?.trim()
        if (raw.isNullOrEmpty()) return null
        if (!raw.contains("://")) return raw
        val uri = try { Uri.parse(raw) } catch (e: Exception) { return null }
        if (uri.host.isNullOrEmpty()) return null
        return when (uri.scheme?.lowercase()) {
            "https" -> raw
            "http" -> if (allowCleartext) raw else null
            else -> null
        }
    }
}
