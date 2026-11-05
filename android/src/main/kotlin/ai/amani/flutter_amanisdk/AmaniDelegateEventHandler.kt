package ai.amani.flutter_amanisdk

import ai.amani.sdk.Amani
import ai.amani.sdk.interfaces.AmaniEventCallBack
import ai.amani.sdk.model.amani_events.error.AmaniError
import ai.amani.sdk.model.amani_events.profile_status.ProfileStatus
import ai.amani.sdk.model.amani_events.steps_result.StepsResult
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel

/**
 * Forwards the Core SDK's AmaniEvent callbacks to the Flutter delegate stream.
 *
 * The Core SDK's `AmaniEvent().setListener(...)` replaces the previous listener, and
 * for API v2 it only wires the SSE stream when `Amani.configure(version = V2)` has
 * already run. Dart can start listening at any time (the example app does it before
 * the SDK is configured), so the listener must be (re)attached once the SDK is
 * configured, no matter when `onListen` fired.
 */
class AmaniDelegateEventHandler : EventChannel.StreamHandler {

  private val mainHandler = Handler(Looper.getMainLooper())

  // Active Flutter sink. Read on every emit so a replaced or cancelled sink is respected.
  @Volatile
  private var eventSink: EventChannel.EventSink? = null

  // Only touched on the main thread.
  private var isSdkConfigured = false
  private var isAttached = false

  // One callback instance for the lifetime of this handler.
  private val callback = object : AmaniEventCallBack {
    override fun onError(type: String?, error: ArrayList<AmaniError?>?) {
      if (error == null) return
      emit(
        mapOf(
          "type" to "error",
          "data" to mapOf(
            "errorType" to type,
            "errors" to Gson().toJson(error)
          )
        )
      )
    }

    override fun profileStatus(profileStatus: ProfileStatus) {
      emit(
        mapOf(
          "type" to "profileStatus",
          "data" to Gson().toJson(profileStatus)
        )
      )
    }

    override fun stepsResult(stepsResult: StepsResult?) {
      if (stepsResult == null) return
      emit(
        mapOf(
          "type" to "stepModel",
          "data" to Gson().toJson(stepsResult)
        )
      )
    }
  }

  private fun emit(event: Map<String, Any?>) {
    mainHandler.post {
      eventSink?.success(event)
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    attachToSdk()
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
    runOnMain {
      if (isAttached) {
        try {
          Amani.sharedInstance().AmaniEvent().removeListener()
        } catch (e: Exception) {
          Log.w(TAG, "removeListener failed", e)
        }
        // The next onListen re-attaches, which also lets the SDK recover missed verdicts.
        isAttached = false
      }
    }
  }

  /**
   * Call after `Amani.configure(...)` succeeded. A listener registered before this
   * point does not get the v2 SSE wiring, so attach again from scratch.
   */
  fun onSdkConfigured() {
    runOnMain {
      isSdkConfigured = true
      isAttached = false
      attachToSdk()
    }
  }

  /**
   * Binds the Core SDK's AmaniEvent listener to the current sink. Safe to call any
   * number of times: it does nothing while there is no sink, before the SDK is
   * configured, or when the listener is already attached. A failure is logged and
   * retried on the next call.
   */
  fun attachToSdk() {
    runOnMain {
      if (eventSink == null || !isSdkConfigured || isAttached) return@runOnMain
      try {
        Amani.sharedInstance().AmaniEvent().setListener(callback)
        isAttached = true
      } catch (e: Exception) {
        Log.w(TAG, "AmaniEvent listener could not be attached yet, will retry", e)
      }
    }
  }

  /** Releases the sink and the Core SDK listener when the Flutter engine goes away. */
  fun dispose() {
    eventSink = null
    runOnMain {
      if (isAttached) {
        try {
          Amani.sharedInstance().AmaniEvent().removeListener()
        } catch (e: Exception) {
          Log.w(TAG, "removeListener failed", e)
        }
      }
      isAttached = false
      isSdkConfigured = false
    }
  }

  private fun runOnMain(block: () -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      block()
    } else {
      mainHandler.post(block)
    }
  }

  private companion object {
    const val TAG = "AmaniDelegateEvent"
  }
}
