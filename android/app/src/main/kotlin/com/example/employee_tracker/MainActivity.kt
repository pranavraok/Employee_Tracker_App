package com.example.employee_tracker

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "device_admin_channel"
    private val REQUEST_CODE_ENABLE_ADMIN = 1

    private var devicePolicyManager: DevicePolicyManager? = null
    private var adminComponent: ComponentName? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, MyDeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDeviceAdmin" -> requestDeviceAdmin(result)
                "isDeviceAdminActive" -> {
                    val isActive = devicePolicyManager?.isAdminActive(adminComponent!!) ?: false
                    result.success(isActive)
                }
                "removeDeviceAdmin" -> {
                    devicePolicyManager?.removeActiveAdmin(adminComponent!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestDeviceAdmin(result: MethodChannel.Result) {
        pendingResult = result

        val isActive = devicePolicyManager?.isAdminActive(adminComponent!!) ?: false
        if (isActive) {
            result.success(true)
            return
        }

        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "This app requires device admin to prevent uninstallation for employee tracking."
        )
        startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            pendingResult?.let {
                it.success(resultCode == Activity.RESULT_OK)
                pendingResult = null
            }
        }
    }
}

