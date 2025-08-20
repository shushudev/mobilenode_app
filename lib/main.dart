import 'package:flutter/material.dart';
import 'provider/provider.dart';
import 'package:provider/provider.dart';
import 'screens/entry_screen.dart';
import 'lightnode_bridge.dart'; // LightNodeBridge import 추가
import 'package:flutter_background_service/flutter_background_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await LightNodeBridge.initKeys(); // 키 초기화
   // 백그라운드 서비스 초기화
  await initializeService();

  runApp(const MyApp());
}

/// 포그라운드 서비스 초기화 함수
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, 
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    debugPrint("[BackgroundService] running...");
    // LightNodeBridge.ping() 같은 유지 로직 추가 가능
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  debugPrint('[BackgroundService] iOS background fetch');
  return true;
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Management management = Management();

  @override
  void initState() {
    super.initState();
  }

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
