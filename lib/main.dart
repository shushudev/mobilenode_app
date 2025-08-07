import 'package:flutter/material.dart';
import 'screens/entry_screen.dart';
import 'lightnode_bridge.dart'; // LightNodeBridge import 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await LightNodeBridge.initKeys(); // ✅ 키 초기화
  LightNodeBridge.initListener();   // ✅ MethodChannel listener 등록

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightNode App',
      home: EntryScreen(),
    );
  }
}
