package com.example.mobilenode_app

import com.example.lightnode.lightnode.Lightnode
import com.example.lightnode.lightnode.SignatureRequestCallback
import com.example.lightnode.lightnode.BalanceCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "lightnode"
    private val BALANCE_CHANNEL = "com.mobilenode/balance"

    private lateinit var methodChannel: MethodChannel
    private var balanceEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel (Flutter → Kotlin → Go 호출)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // EventChannel (Go → Kotlin → Flutter 스트림 전달: balance)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BALANCE_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    balanceEventSink = events
                    println("✅ Balance EventChannel listener 등록됨")
                }
                override fun onCancel(arguments: Any?) {
                    balanceEventSink = null
                    println("⚠️ Balance EventChannel listener 해제됨")
                }
            })

        // MethodChannel 핸들러
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

        // Go → Kotlin 콜백 등록

        // ✅ Signature 요청 콜백
        Lightnode.setSignatureRequestCallback(object : SignatureRequestCallback {
            override fun invoke(hashBase64: String) {
                println("📢 [Kotlin] SignatureRequestCallback 호출됨 → $hashBase64")
                runOnUiThread {
                    try {
                        methodChannel.invokeMethod("onSignatureRequest", hashBase64)
                        println("📢 Flutter로 onSignatureRequest 전달 완료")
                    } catch (e: Exception) {
                        println("❌ Flutter invokeMethod 오류: ${e.message}")
                    }
                }
            }
        })
        println("✅ SignatureRequestCallback 등록 완료")

        // ✅ Balance 콜백
        Lightnode.setBalanceCallback(object : BalanceCallback {
            override fun onBalance(balanceJson: String) {
                println("📢 [Kotlin] BalanceCallback 호출됨 → $balanceJson")
                runOnUiThread {
                    balanceEventSink?.success(balanceJson)
                }
            }
        })
        println("✅ BalanceCallback 등록 완료")
    }
}
