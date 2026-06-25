import 'package:flutter/material.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA3D1C6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFA3D1C6),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('비밀번호 찾기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 72, 34, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '가입한 메일주소를 입력해주세요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 26),
              LoginTextField(
                controller: emailController,
                hintText: '메일주소',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 48),
              LoginButton(
                label: '확인',
                onPressed: () => Navigator.pop(context),
                backgroundColor: const Color(0xFFE67E22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
