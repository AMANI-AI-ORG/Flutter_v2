package ai.amani.flutter_amanisdk.modules

import ai.amani.sdk.interfaces.IUploadCallBack
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Upload callback for the `upload...WithDocumentId` channel methods.
 * Flutter receives: {"isSuccess": Boolean, "documentId": String?}
 *
 * The SDK's `uploadCallBack { isSuccess, documentID -> }` adapter only forwards
 * `cb(Boolean, String)`; its `cb(Boolean)` is empty. Several SDK paths, mostly
 * failures, report through `cb(Boolean)` only, which would leave the Flutter call
 * waiting forever. This callback handles both overloads and replies exactly once.
 */
fun MethodChannel.Result.uploadResultCallBack(module: String): IUploadCallBack {
    val result = this
    val replied = AtomicBoolean(false)

    fun reply(isSuccess: Boolean, documentId: String?) {
        if (!replied.compareAndSet(false, true)) return
        Log.d("AmaniBridge", "[$module] upload result isSuccess=$isSuccess documentId=$documentId")
        val payload = mapOf("isSuccess" to isSuccess, "documentId" to documentId)
        Handler(Looper.getMainLooper()).post { result.success(payload) }
    }

    return object : IUploadCallBack {
        override fun cb(isSuccess: Boolean) = reply(isSuccess, null)
        override fun cb(isSuccess: Boolean, documentId: String?) = reply(isSuccess, documentId)
    }
}

/** Replies to Flutter with a failed upload result, for errors caught before the SDK call. */
fun MethodChannel.Result.uploadResultFailure(module: String, message: String?) {
    Log.e("AmaniBridge", "[$module] upload failed: $message")
    val payload = mapOf("isSuccess" to false, "documentId" to null)
    Handler(Looper.getMainLooper()).post { success(payload) }
}
