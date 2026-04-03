package com.jamart3d.shakedown

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts

class StereoCapturePermissionActivity : ComponentActivity() {
    companion object {
        private const val TAG = "StereoCapturePerm"
    }

    private val captureLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { activityResult ->
        Log.i(
            TAG,
            "Permission activity result received (resultCode=${activityResult.resultCode}, hasData=${activityResult.data != null})"
        )
        setResult(activityResult.resultCode, activityResult.data)
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as? MediaProjectionManager
        if (mgr == null) {
            Log.w(TAG, "MediaProjectionManager unavailable")
            setResult(Activity.RESULT_CANCELED)
            finish()
            return
        }

        try {
            Log.i(TAG, "Launching MediaProjection consent activity")
            captureLauncher.launch(mgr.createScreenCaptureIntent())
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to launch MediaProjection consent activity", t)
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }
}
