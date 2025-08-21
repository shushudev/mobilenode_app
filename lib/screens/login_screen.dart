import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobilenode_app/provider/provider.dart';
import '../widgets/custom_input.dart';
import '../services/auth_service.dart';
import '../lightnode_bridge.dart';
import '../lightnode_screen.dart'; // 로그인 성공 후 이동할 화면
import 'balance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.management});

  final Management management;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

const platform = MethodChannel('lightnode');

class _LoginScreenState extends State<LoginScreen> {
  final deviceIdController = TextEditingController();
  final nodeIdController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    deviceIdController.dispose();
    nodeIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() async {
    final deviceId = deviceIdController.text.trim();
    final nodeId = nodeIdController.text.trim();
    final password = passwordController.text;

    if (deviceId.isEmpty || nodeId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 필드를 채워주세요.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final success = await verifyCredentials(
      deviceId: deviceId,
      nodeId: nodeId,
      password: password,
    );
    

    setState(() {
      isLoading = false;
    });

    if (success) {
    try {
      // 로그인 성공 시, Go 라이트노드 시작 요청
      await platform.invokeMethod('startLightNode', {
        'deviceId': deviceId,
        'nodeId': nodeId,
        'password': password,
      });
      
      await LightNodeBridge.initKeys(); // 키 다시 초기화
      LightNodeBridge.initListener();  
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("로그인 성공 및 키 초기화 완료")),
    );
      print("✅ LightNode 실행 요청 성공");
      
    } catch (e) {
      print("❌ LightNode 실행 요청 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("노드 실행에 실패했습니다.")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LightNodeScreen(management: widget.management,)),
    );
  } else {
    setState(() {
      isLoading = false;
    });
    print("❌ 로그인 실패");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("로그인 실패")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomInput(label: "Device ID", controller: deviceIdController),
            CustomInput(label: "Node ID", controller: nodeIdController),
            CustomInput(
              label: "Password",
              controller: passwordController,
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleLogin,
                    child: Text("로그인"),
                  ),
          ],
        ),
      ),
    );
  }
}
