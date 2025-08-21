import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  static const balanceChannel = EventChannel("com.mobilenode/balance");
  String balance = "0";

  @override
  void initState() {
    super.initState();
    balanceChannel.receiveBroadcastStream().listen((event) {
      final data = json.decode(event as String);
      setState(() {
        balance = data['balance'];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Balance: $balance")),
    );
  }
}
