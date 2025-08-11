import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:crypto/crypto.dart' as crypto;
import 'package:bech32/bech32.dart';
import 'dart:convert';
import 'dart:typed_data';

final secureStorage = FlutterSecureStorage();

String addPrefixToPubKey(Uint8List pubKey32) {
  // 1바이트 prefix (예: 0xED)
  const int prefix = 0xED;

  // 33바이트 버퍼 생성
  final prefixedKey = Uint8List(pubKey32.length + 1);

  // prefix 추가
  prefixedKey[0] = prefix;

  // 기존 32바이트 키 복사
  for (int i = 0; i < pubKey32.length; i++) {
    prefixedKey[i + 1] = pubKey32[i];
  }

  // Base64 인코딩해서 리턴
  return base64.encode(prefixedKey);
}

Future<void> generateAndStoreKeys({
  required String nodeId,
  required String deviceId,
  required String password,
}) async {
  // 1. Ed25519 키 쌍 생성
  final keyPair = ed.generateKey();
  final privateKey = keyPair.privateKey;
  final publicKey = keyPair.publicKey;

  final privKeyBase64 = base64.encode(privateKey.bytes);
  final pubKeyBase64 = base64.encode(publicKey.bytes);

  //3. 주소 생성 (Cosmos 방식)
  // Ed25519 Public Key → SHA256 → RIPEMD160 → Bech32
  final sha256Digest = crypto.sha256.convert(publicKey.bytes);
  final ripemd = RIPEMD160Digest();
  final ripemdDigest = ripemd.process(Uint8List.fromList(sha256Digest.bytes));

  final fiveBit = convertBits(ripemdDigest, 8, 5, true);
  final cosmosAddress = bech32.encode(Bech32('cosmos', fiveBit));


  // 4. 키 저장 (Base64)
  await secureStorage.write(key: 'private_key', value: privKeyBase64);
  await secureStorage.write(key: 'public_key', value: pubKeyBase64);

  print("✅ Public Key 저장: $pubKeyBase64");
  print("✅ Cosmos 주소: $cosmosAddress");

  // 5. 서버에 등록 요청
  final body = json.encode({
    'node_id': nodeId,
    'device_id': deviceId,
    'password': password,
    'public_key': publicKey,
    'address': cosmosAddress, // ← 추가된 부분
  });


  final res = await http.post(
    Uri.parse('http://192.168.0.131:3001/connect'),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (res.statusCode == 200) {
    print("✅ 등록 성공: $cosmosAddress");
  } else {
    print("❌ 등록 실패: ${res.statusCode}");
  }
}

Future<Map<String, String>> signWithEd25519(String hashBase64) async {
  final privKeyBase64 = await secureStorage.read(key: 'private_key');
  final pubKeyBase64 = await secureStorage.read(key: 'public_key');

  if (privKeyBase64 == null || pubKeyBase64 == null) {
    throw Exception("❌ 키가 없습니다.");
  }

  final privateKey = ed.PrivateKey(base64.decode(privKeyBase64));
  final publicKeyBytes = base64.decode(pubKeyBase64);
  final hashBytes = base64.decode(hashBase64);

  // ✅ Ed25519 서명
  final signature = ed.sign(privateKey, hashBytes);

  return {
    "signature": base64.encode(signature),
    "publicKey": base64.encode(publicKeyBytes),
  };
}


/// ✅ 비트 변환 (8비트 → 5비트)
List<int> convertBits(List<int> data, int from, int to, bool pad) {
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