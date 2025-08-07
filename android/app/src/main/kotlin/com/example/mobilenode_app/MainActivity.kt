package com.example.mobilenode_app

import com.example.lightnode.lightnode.Lightnode
import com.example.lightnode.lightnode.SignatureRequestCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val CHANNEL = "lightnode"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startLightNode" -> {
                    val res = Lightnode.startLightNode()
                    result.success(res)
                }
                "getStatus" -> {
                    val status = Lightnode.getStatus()
                    result.success(status)
                }
                "initProducer" -> {
                    val brokers = call.argument<String>("brokers") ?: ""
                    val res = Lightnode.initProducer(brokers)
                    result.success(res)
                }
                "requestSignature" -> {
                    val data = call.argument<String>("data") ?: "{}"
                    val hash = Lightnode.requestSignature(data)
                    result.success(hash)
                }
                "sendSignature" -> {
                    val signature = call.argument<String>("signature") ?: ""
                    val publicKey = call.argument<String>("pubKey") ?: ""
                    val hash = call.argument<String>("hash") ?: ""
                    println("✅ sendSignature 호출됨 → signature: $signature, pubKey: $publicKey, hash: $hash")
                    val res = Lightnode.sendSignature(signature, publicKey, hash)
                    result.success(res)
                }
                else -> result.notImplemented()
            }
        }

        // ✅ 콜백 설정 (Java 인터페이스 구현)
        Lightnode.setSignatureRequestCallback(object : SignatureRequestCallback {
            override fun invoke(hashBase64: String) {
                println("📢 서명 요청 수신 → Flutter로 전달: $hashBase64")
                methodChannel.invokeMethod("onSignatureRequest", hashBase64)
            }
        })
    }
}
