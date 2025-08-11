import 'dart:convert';
import 'package:http/http.dart' as http;

/// 서버 URL
const String baseUrl = 'http://192.168.0.131:3001';

/// 로그인 검증
Future<bool> verifyCredentials({
  required String deviceId,
  required String nodeId,
  required String password,
}) async {
  try {
    final url = Uri.parse('$baseUrl/verify');
    final body = json.encode({
      'device_id': deviceId,
      'node_id': nodeId,
      'password': password,
    });

    print("📤 [LOGIN REQUEST] URL: $url");
    print("📦 Body: $body");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("📥 [LOGIN RESPONSE] Status: ${response.statusCode}");
    print("📥 Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == 'success';
    } else {
      return false;
    }
  } catch (e) {
    print("❌ 로그인 요청 오류: $e");
    return false;
  }
}

/// 회원가입 요청
Future<bool> registerUser({
  required String nodeId,
  required String deviceId,
  required String password,
  required String publicKey,
  required String address,
}) async {
  try {
    final url = Uri.parse('$baseUrl/connect');
    final body = json.encode({
      'node_id': nodeId,
      'device_id': deviceId,
      'password': password, // bcrypt 해시화는 서버에서 처리 권장
      'public_key': publicKey,
      'address': address,
    });

    print("📤 [REGISTER REQUEST] URL: $url");
    print("📦 Body: $body");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print("📥 [REGISTER RESPONSE] Status: ${response.statusCode}");
    print("📥 Body: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == 'success';
    } else {
      return false;
    }
  } catch (e) {
    print("❌ 회원가입 요청 오류: $e");
    return false;
  }
}
