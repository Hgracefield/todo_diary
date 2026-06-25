import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/view/home.dart';
import 'package:my_todo_list_app/view/login/find_password_page.dart';
import 'package:my_todo_list_app/view/login/sign_page.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final api = RestApiService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('메일주소와 비밀번호를 입력해주세요.');
      return;
    }

    try {
      final user = await api.login(email: email, password: password);
      if (user.userId == null) {
        throw const ApiException(statusCode: 500, message: '사용자 ID가 없습니다.');
      }
      await SessionStorage.login(
        userId: user.userId!,
        email: user.userEmail,
        password: password,
        name: user.userName,
        birthDate: user.userBirthDate,
        phone: user.userPhone,
        address: user.userAddress,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } on ApiException catch (error) {
      _showMessage(
        error.statusCode == 401 ? '메일주소 또는 비밀번호를 확인해주세요.' : '서버에 연결할 수 없습니다.',
      );
    } catch (_) {
      _showMessage('서버에 연결할 수 없습니다.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSignPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignPage()),
    );
  }

  void _openFindPasswordPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFEDF2F1),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final logoHeight = (height * 0.115).clamp(72.0, 98.0);
            final logoWidth = logoHeight * 2.25;
            const fieldHeight = 45.0;
            final buttonHeight = (height * 0.068).clamp(52.0, 62.0);
            const fieldFontSize = 16.0;
            const buttonFontSize = 16.0;
            const sidePadding = 20.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: Column(
                children: [
                  SizedBox(height: height * 0.07),
                  Image.asset(
                    'images/lalo-icon.png',
                    width: logoWidth,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: height * 0.04),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '라이프를 더 쉽게 정리하고,\n로그로 더 오래 기억하는 나만의 하루 기록 앱',
                      style: TextStyle(
                        color: Color.fromARGB(255, 163, 209, 198),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.075),
                  LoginTextField(
                    controller: emailController,
                    hintText: '메일주소',
                    keyboardType: TextInputType.emailAddress,
                    height: fieldHeight,
                    fontSize: fieldFontSize,
                  ),
                  SizedBox(height: height * 0.014),
                  LoginTextField(
                    controller: passwordController,
                    hintText: '비밀번호',
                    obscureText: true,
                    height: fieldHeight,
                    fontSize: fieldFontSize,
                  ),
                  SizedBox(height: height * 0.012),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _openFindPasswordPage,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0x36FFFFFF),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '정보를 잊어버리셨나요?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 163, 209, 198),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.045),
                  LoginButton(
                    label: '로그인',
                    onPressed: _login,
                    backgroundColor: const Color(0xFFA3D1C6),
                    height: buttonHeight,
                    fontSize: buttonFontSize,
                  ),
                  SizedBox(height: height * 0.016),
                  LoginButton(
                    label: '구글로 로그인',
                    onPressed: () => _showMessage('구글 로그인은 아직 준비 중입니다.'),
                    backgroundColor: Colors.black,
                    height: buttonHeight,
                    fontSize: buttonFontSize,
                  ),
                  SizedBox(height: height * 0.016),
                  LoginButton(
                    label: '회원가입',
                    onPressed: _openSignPage,
                    backgroundColor: const Color(0xFFE67E22),
                    height: buttonHeight,
                    fontSize: buttonFontSize,
                  ),
                  const Spacer(),
                  Text(
                    '© 2026 라로(Life-LOG). All Rights Reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0x24FFFFFF),
                      fontSize: (height * 0.016).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
