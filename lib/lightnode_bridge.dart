import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/digests/ripemd160.dart';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:crypto/crypto.dart' as crypto;
import 'package:bech32/bech32.dart';



/// 8비트 → 5비트 변환 (Bech32용)

/// 📦 Isolate에서 사용할 Top-Level 함수 (compute로 호출됨)
Future<String> _signInIsolate(Map<String, dynamic> params) async {
  final Uint8List privateKeyBytes = params['privateKeyBytes'];
  final String payload = params['payload'];

  final ed.PrivateKey privateKey = ed.PrivateKey(privateKeyBytes);
  final messageBytes = utf8.encode(payload);
  final signatureBytes = ed.sign(privateKey, Uint8List.fromList(messageBytes));
  return base64Encode(signatureBytes);
}

/// 📡 LightNodeBridge 클래스
class LightNodeBridge {
  
  static const MethodChannel _channel = MethodChannel('lightnode');
  static const _storage = FlutterSecureStorage();

  static late ed.PrivateKey _privateKey;
  static late ed.PublicKey _publicKey;
  static late String _cosmosAddress;

  /// 🔑 키 초기화 (저장된 키가 없으면 새로 생성)
  /// 🔑 키 초기화 (저장된 키가 없으면 새로 생성)
static Future<void> initKeys() async {
  final privateKeyBase64 = await _storage.read(key: 'privateKey');
  final publicKeyBase64 = await _storage.read(key: 'publicKey');
  final cosmosAddressStored = await _storage.read(key: 'cosmosAddress');

  if (privateKeyBase64 != null && publicKeyBase64 != null && cosmosAddressStored != null) {
    _privateKey = ed.PrivateKey(Uint8List.fromList(base64Decode(privateKeyBase64)));
    _publicKey = ed.PublicKey(Uint8List.fromList(base64Decode(publicKeyBase64)));
    _cosmosAddress = cosmosAddressStored;
    print("✅ 기존 키와 주소 로드 완료: $_cosmosAddress");
  } else {
    // 새 키 생성
    final keyPair = ed.generateKey();
    _privateKey = keyPair.privateKey;
    _publicKey = keyPair.publicKey;

    // Cosmos 주소 생성 (SHA256 → RIPEMD160 → Bech32)
    final sha256Digest = crypto.sha256.convert(_publicKey.bytes);
    final ripemd = RIPEMD160Digest();
    final ripemdDigest = ripemd.process(Uint8List.fromList(sha256Digest.bytes));
    final fiveBit = convertBits(ripemdDigest, 8, 5, true);
    _cosmosAddress = bech32.encode(Bech32('cosmos', fiveBit));

    // 저장
    await _storage.write(key: 'privateKey', value: base64Encode(_privateKey.bytes));
    await _storage.write(key: 'publicKey', value: base64Encode(_publicKey.bytes));
    await _storage.write(key: 'cosmosAddress', value: _cosmosAddress);

    print("🔑 새 키와 주소 생성 완료: $_cosmosAddress");
  }
}


  /// 🧠 Isolate를 활용한 서명 함수
  static Future<String> signPayload(String payload) async {
    final params = {
      'privateKeyBytes': _privateKey.bytes,
      'payload': payload,
    };
    final signature = await compute(_signInIsolate, params);
    return signature;
  }

  /// 📡 Native -> Dart 메서드 호출 처리
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

          return result;
        } catch (e) {
          print("❌ 서명 처리 실패 (onSignatureRequest): $e");
          throw PlatformException(code: 'SIGN_FAILED', message: e.toString());
        }

      } else {
        print("⚠️ 알 수 없는 메서드 호출: ${call.method}");
        throw PlatformException(
          code: 'METHOD_NOT_IMPLEMENTED',
          message: 'Unknown method ${call.method}',
        );
      }
    });

    print("✅ initListener() 등록됨");
  }


  /// ✅ 상태 가져오기
  static Future<String?> getStatus() async {
    try {
      final String? status = await _channel.invokeMethod('getStatus');
      return status;
    } catch (e) {
      print('❌ getStatus 호출 실패: $e');
      return null;
    }
  }

/// 8비트 → 5비트 변환 (Bech32용)
static List<int> convertBits(List<int> data, int from, int to, bool pad) {
  int acc = 0;
  int bits = 0;
  List<int> ret = [];
  final maxv = (1 << to) - 1;

  for (final value in data) {
    if (value < 0 || (value >> from) != 0) {
      throw FormatException("Invalid value: $value");
    }
    acc = (acc << from) | value;
    bits += from;
    while (bits >= to) {
      bits -= to;
      ret.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      ret.add((acc << (to - bits)) & maxv);
    }
  } else if (bits >= from || ((acc << (to - bits)) & maxv) != 0) {
    throw FormatException("Conversion error");
  }

  return ret;
}

  /// 🚀 라이트 노드 시작
  static Future<String?> startLightNode() async {
    try {
      final String? result = await _channel.invokeMethod('startLightNode');
      return result;
    } catch (e) {
      print('❌ startLightNode 호출 실패: $e');
      return null;
    }
  }

  /// 📝 서명 결과 전송
  static Future<String?> sendSignature(
    String signature,
    String pubKey,
    String hash,
  ) async {
    try {
      final String? result = await _channel.invokeMethod('sendSignature', {
        'signature': signature,
        'pubKey': pubKey,
        'hash': hash,
      });
      print("📤 sendSignature 호출 성공: $result");
      return result;
    } catch (e) {
      print('❌ sendSignature 호출 실패: $e');
      return null;
    }
  }
}
