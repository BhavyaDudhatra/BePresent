package com.bepresent

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val smsChannel = "com.bepresent/sms"
    private val sendSmsRequestCode = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMessages: List<Map<String, String>> = emptyList()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendBatch" -> handleSendBatch(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSendBatch(call: MethodCall, result: MethodChannel.Result) {
        val messages = call.argument<List<Map<String, String>>>("messages") ?: emptyList()
        if (messages.isEmpty()) {
            result.success(0)
            return
        }

        when {
            hasSmsPermission() -> deliverSmsBatch(messages, result)
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                pendingResult = result
                pendingMessages = messages
                requestPermissions(
                    arrayOf(Manifest.permission.SEND_SMS),
                    sendSmsRequestCode
                )
            }
            else -> deliverSmsBatch(messages, result)
        }
    }

    private fun hasSmsPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.SEND_SMS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun deliverSmsBatch(
        messages: List<Map<String, String>>,
        result: MethodChannel.Result
    ) {
        try {
            val smsManager = SmsManager.getDefault()
            var sent = 0
            for (message in messages) {
                val phone = message["phone"] ?: continue
                val text = message["message"] ?: continue
                smsManager.sendTextMessage(phone, null, text, null, null)
                sent++
            }
            result.success(sent)
        } catch (e: Exception) {
            result.error("SMS_SEND_FAILED", e.message, null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == sendSmsRequestCode) {
            val result = pendingResult
            val messages = pendingMessages
            pendingResult = null
            pendingMessages = emptyList()
            if (result == null) return

            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                deliverSmsBatch(messages, result)
            } else {
                result.error("SMS_PERMISSION_DENIED", "SMS permission was denied", null)
            }
        }
    }
}