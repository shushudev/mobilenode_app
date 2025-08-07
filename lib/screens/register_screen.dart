import 'package:flutter/material.dart';
import '../widgets/custom_input.dart'; // 상대 경로 import
import '../services/ed25519_service.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nodeIdController = TextEditingController();
  final deviceIdController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nodeIdController.dispose();
    deviceIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    final nodeId = nodeIdController.text.trim();
    final deviceId = deviceIdController.text.trim();
    final password = passwordController.text;

    if (nodeId.isEmpty || deviceId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("모든 필드를 채워주세요.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await generateAndStoreKeys(
        nodeId: nodeId,
        deviceId: deviceId,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("가입이 완료되었습니다.")),
      );

      Navigator.pop(context); // 가입 완료 후 이전 화면(로그인)으로 돌아가기
    } catch (e) {
      print('키 생성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("가입 중 오류가 발생했습니다.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomInput(label: "Node ID", controller: nodeIdController),
            CustomInput(label: "Device ID", controller: deviceIdController),
            CustomInput(
              label: "Password",
              controller: passwordController,
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleRegister,
                    child: Text("가입하기"),
                  ),
          ],
        ),
      ),
    );
  }
}
