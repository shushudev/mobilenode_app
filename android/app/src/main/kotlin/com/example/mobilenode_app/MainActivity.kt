package com.example.mobilenode_app

import com.example.lightnode.lightnode.Lightnode
import com.example.lightnode.lightnode.SignatureRequestCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val CHANNEL = "lightnode"
    private val BALANCE_CHANNEL = "com.mobilenode/balance"
    private lateinit var methodChannel: MethodChannel
    private var balanceEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
         // EventChannel 설정
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BALANCE_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    balanceEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    balanceEventSink = null
                }
            })

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
                "sendBalance" -> {
                    val brokers = call.argument<String>("brokers") ?: "[]"
                    val topic = call.argument<String>("topic") ?: "balance-topic"
                    Lightnode.sendBalance(brokers, topic)
                    result.success("Balance listener started")
                }
                else -> result.notImplemented()
            }
        }

        // ✅ 콜백 설정 (Java 인터페이스 구현)
        Lightnode.setSignatureRequestCallback(object : SignatureRequestCallback {
        override fun invoke(hashBase64: String) {
        
        println("📢 [Kotlin] SignatureRequestCallback 호출됨")
        println("📢 서명 요청 수신 → Flutter로 전달: $hashBase64")

        runOnUiThread {
            try {
                methodChannel.invokeMethod("onSignatureRequest", hashBase64)
                println("📢 invokeMethod 호출 완료")
            } catch (e: Exception) {
                println("❌ invokeMethod 호출 중 오류: ${e.message}")
            }
        }
    }
})

      // Balance 콜백 설정
        Lightnode.setBalanceCallback { jsonStr ->
            runOnUiThread {
                balanceEventSink?.success(jsonStr)
            }
        }
    }
}
