import 'package:flutter/material.dart';
import 'package:mobilenode_app/provider/provider.dart';
import 'package:provider/provider.dart';
import 'screens/entry_screen.dart';
import 'lightnode_bridge.dart'; // LightNodeBridge import 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await LightNodeBridge.initKeys(); // ✅ 키 초기화
  LightNodeBridge.initListener();   // ✅ MethodChannel listener 등록

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Management management = Management();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => management,
      child: Consumer<Management>(
        builder: (context, dataManagement, child) {
          return MaterialApp(
            title: 'LightNode App',
            theme: ThemeData().copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
            ),
            home: EntryScreen(management: management),
          );
        },
      ),
    );
  }
}
