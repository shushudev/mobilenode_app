package com.example.mobilenode_app.lightnode

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodCall
import com.example.lightnode.lightnode.Lightnode

class LightNodePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "lightnode")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> {
                try {
                    val status = Lightnode.getStatus()  // static 호출 형태로
                    result.success(status)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "startLightNode" -> {
                try {
                    val response = Lightnode.startLightNode()  // 마찬가지로 static 호출
                    result.success(response)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
