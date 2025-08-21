import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  static const balanceChannel = EventChannel("com.mobilenode/balance");
  final storage = const FlutterSecureStorage();
  String balance = "0";
  String myAddress = "";

  @override
  void initState() {
    super.initState();
    _loadMyAddress();
  }

  Future<void> _loadMyAddress() async {
    // Secure Storage에서 자기 주소 가져오기
    final storedAddress = await storage.read(key: 'cosmos_address');
    if (storedAddress != null) {
      myAddress = storedAddress;

      // EventChannel 구독 시작
      balanceChannel.receiveBroadcastStream().listen((event) {
        try {
          final data = json.decode(event as String);

          // 자기 주소와 일치할 때만 balance 업데이트
          if (data['address'] == myAddress) {
            setState(() {
              balance = data['balance'];
            });
          }
        } catch (e) {
          print("❌ Balance parsing error: $e");
        }
      });
    } else {
      print("❌ SecureStorage에서 주소를 읽을 수 없음");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Balance")),
      body: Center(child: Text("Balance: $balance")),
    );
  }
}
