import 'package:flutter/material.dart';
import 'package:mobilenode_app/provider/provider.dart';
import 'package:provider/provider.dart';
import 'lightnode_bridge.dart';
import 'package:mobilenode_app/screens/balance_screen.dart';


class LightNodeScreen extends StatefulWidget {
  const LightNodeScreen({super.key, required this.management});
  final Management management;
  @override
  State<LightNodeScreen> createState() => _LightNodeScreenState();
}

class _LightNodeScreenState extends State<LightNodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LightNode Test')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text("${widget.management.balance}"),),
          ElevatedButton(
            onPressed: () async {
              final status = await LightNodeBridge.getStatus();
              print('LightNode Status: $status');
            },
            child: Text('Check Status'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final result = await LightNodeBridge.startLightNode();
              print('Start Result: $result');
            },
            child: Text('Start LightNode'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BalanceScreen(management: widget.management),
                ),
              );
            },
            child: Text('Balance'),
          ),
        ],
      ),
    );
  }
}
