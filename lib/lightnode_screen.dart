import 'package:flutter/material.dart';
import 'lightnode_bridge.dart';

class LightNodeScreen extends StatelessWidget {
  const LightNodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LightNode Test')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }
}
