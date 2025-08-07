import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class LightNodeBridge {
  static const MethodChannel _channel = MethodChannel('lightnode');
  static const _storage = FlutterSecureStorage();

  static late ed.PrivateKey _privateKey;
  static late ed.PublicKey _publicKey;

  /// 초기화 시 저장된 키 불러오기 (없으면 새로 생성)
  static Future<void> initKeys() async {
    final privateKeyBase64 = await _storage.read(key: 'privateKey');
    final publicKeyBase64 = await _storage.read(key: 'publicKey');

    if (privateKeyBase64 != null && publicKeyBase64 != null) {
      _privateKey = ed.PrivateKey(Uint8List.fromList(base64Decode(privateKeyBase64)));
      _publicKey = ed.PublicKey(Uint8List.fromList(base64Decode(publicKeyBase64)));
      print("✅ 기존 키 로드 완료");
    } else {
      final keyPair = ed.generateKey();
      _privateKey = keyPair.privateKey;
      _publicKey = keyPair.publicKey;

      await _storage.write(key: 'privateKey', value: base64Encode(_privateKey.bytes));
      await _storage.write(key: 'publicKey', value: base64Encode(_publicKey.bytes));
      print("🔑 새 키 생성 및 저장 완료");
    }
  }

  static Future<String> signPayload(String payload) async {
    final messageBytes = utf8.encode(payload);
    final signatureBytes = ed.sign(_privateKey, Uint8List.fromList(messageBytes));
    return base64Encode(signatureBytes);
  }

  static void initListener() {
  _channel.setMethodCallHandler((call) async {
    print("📩 MethodCall received from Go: ${call.method}");

    if (call.method == 'sign') {
      final payload = call.arguments as String;
      print("📩 서명 요청 수신 (sign): $payload");

      try {
        final signature = await signPayload(payload);
        print("✅ 서명 완료 (sign): $signature");
        return signature;
      } catch (e) {
        print("❌ 서명 처리 실패 (sign): $e");
        throw PlatformException(code: 'SIGN_FAILED', message: e.toString());
      }

    } else if (call.method == 'onSignatureRequest') {
      final hashBase64 = call.arguments as String;
      print("📥 서명 요청 수신 (onSignatureRequest): $hashBase64");

      try {
        final hashBytes = base64Decode(hashBase64);
        final signatureBytes = ed.sign(_privateKey, hashBytes);
        final signatureBase64 = base64Encode(signatureBytes);
        final pubKeyBase64 = base64Encode(_publicKey.bytes);

        final result = await sendSignature(signatureBase64, pubKeyBase64, hashBase64);
        print("✅ sendSignature 결과: $result");
      } catch (e) {
        print("❌ 서명 처리 실패 (onSignatureRequest): $e");
        throw PlatformException(code: 'SIGN_FAILED', message: e.toString());
      }

    } else {
      print("⚠️ 알 수 없는 메서드 호출: ${call.method}");
      throw PlatformException(code: 'METHOD_NOT_IMPLEMENTED', message: 'Unknown method ${call.method}');
    }
  });

  print("✅ initListener() 등록됨");
}


  static Future<String?> getStatus() async {
    try {
      final String? status = await _channel.invokeMethod('getStatus');
      return status;
    } catch (e) {
      print('Error calling getStatus: $e');
      return null;
    }
  }
  

  static Future<String?> startLightNode() async {
    try {
      final String? result = await _channel.invokeMethod('startLightNode');
      return result;
    } catch (e) {
      print('Error calling startLightNode: $e');
      return null;
    }
  }
  
  static Future<String?> sendSignature(
    String signature, String pubKey, String hash) async {
    try {
      final String? result = await _channel.invokeMethod('sendSignature', {
        'signature': signature,
        'pubKey': pubKey,
        'hash': hash,
      });
      print("📤 SendSignature 호출 성공: $result");
      return result;
    } catch (e) {
      print('Error calling sendSignature: $e');
      return null;
    }
  }
}
