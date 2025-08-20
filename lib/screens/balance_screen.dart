import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobilenode_app/provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final secureStorage = FlutterSecureStorage();

class BalanceScreen extends StatefulWidget {
  final Management management;
  const BalanceScreen({super.key, required this.management});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse('ws://192.168.131:8080'));
    channel.stream.listen((message) async {
      final data = json.decode(message);
      final msgAddress = data['address'] as String;
      final msgBalance = data['balance'] as String;

      final myAddress = await secureStorage.read(key: 'cosmos_address');
      if (myAddress != null && myAddress == msgAddress) {
        widget.management.setBalance(int.parse(msgBalance));
      }
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Balance: ${widget.management.balance}")),
    );
  }
}
