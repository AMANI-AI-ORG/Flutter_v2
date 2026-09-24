package ai.amani.flutter_amanisdk.modules

import ai.amani.flutter_amanisdk.R
import ai.amani.sdk.Amani
import ai.amani.sdk.interfaces.IUploadCallBack
import ai.amani.sdk.modules.document.DocBuilder
import ai.amani.sdk.modules.document.FileWithType
import ai.amani.sdk.modules.document.interfaces.IDocumentCallBack
import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class DocumentCapture: Module {

    private var docType: String? = null;
    private var frag: Fragment? = null;
    private var closeButton: Button? = null;
    private var filesToUpload: ArrayList<FileWithType>? = null

    companion object {
        val instance = DocumentCapture()
    }

    // stepID is DOCUMENT COUNT
    override fun start(stepID: Int, activity: Activity, result: MethodChannel.Result) {
        if (docType == null) {
            result.error("30013", "You must call setType before calling start method", null)
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

        val id = 0x001115
        val context = activity.applicationContext
        val viewParams = FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        val container = FrameLayout(context)

        container.id = id
        activity.addContentView(container, viewParams)

        frag = Amani.sharedInstance().Document().start(docType, null, container, object: IDocumentCallBack {
            override fun cb(listOfDocumentAbsolutePath: ArrayList<String>?, isSuccess: Boolean) {
                if (listOfDocumentAbsolutePath?.last() == null) {
                    result.error("30013", "No images are returned from DocumentCapture", null)
                }

                val bitmap: Bitmap = BitmapFactory.decodeFile(listOfDocumentAbsolutePath?.last())
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream);
                result.success(stream.toByteArray())

                activity.removeFragment(frag)

                activity.runOnUiThread {
                    closeButton!!.visibility = View.GONE
                }

                frag = null
            }
        })

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
        if (frag == null) {
            result.error(
                "30001",
                "You must call this function while the" +
                        "module is running", "You can ignore this message and return true" +
                        "from onWillPop()"
            )
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

    //                                   data, dataType
    //                                   ByteArray, string
   fun setFiles(files: List<Map<String, Any>>) {
        filesToUpload = files.map {
            val data = it.getValue("data") as ByteArray
            val type = it.getValue("dataType") as String
            FileWithType(data, type)
        } as ArrayList<FileWithType>
    }

    /** Drops files set by an earlier call, so the captured document is uploaded instead. */
    fun clearFiles() {
        filesToUpload = null
    }

    override fun upload(activity: Activity, result: MethodChannel.Result) {

        if (docType == null) {
            result.error("30013", "You must call setType before calling start method", null)
            return
        }

        (activity as FragmentActivity)
        if (filesToUpload == null) {
            Amani.sharedInstance().Document().upload(activity, docType!!, object : IUploadCallBack {
                override fun cb(uploadState: Boolean) {
                    result.success(uploadState)
                }
            })
        } else {
            Amani.sharedInstance().Document().upload(activity, docType!!, filesToUpload!!) {
                result.success(it)
            }
        }
    }

    /** Uploads the captured document or the set files, and returns {"isSuccess": Boolean, "documentId": String?}. */
    fun uploadWithDocumentId(activity: Activity, result: MethodChannel.Result) {
        val type = docType
        if (type == null) {
            result.error("30013", "You must call setType before calling start method", null)
            return
        }
        val fa = activity as FragmentActivity
        val callBack = result.uploadResultCallBack("DocumentCapture")
        try {
            val files = filesToUpload
            if (files == null) {
                Amani.sharedInstance().Document().upload(fa, type, callBack)
            } else {
                Amani.sharedInstance().Document().upload(fa, type, files, callBack)
            }
        } catch (e: Exception) {
            result.uploadResultFailure("DocumentCapture", e.message)
        }
    }

    override fun setType(type: String?, result: MethodChannel.Result) {
        this.docType = type
        result.success(null)
    }


}