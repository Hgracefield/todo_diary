import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';

class FindPasswordPage extends StatefulWidget {
  const FindPasswordPage({super.key});

  @override
  State<FindPasswordPage> createState() => _FindPasswordPageState();
}

class _FindPasswordPageState extends State<FindPasswordPage> {
  final api = RestApiService();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isSearching = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _findAccount() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _showMessage('이름과 핸드폰번호를 입력해주세요.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isSearching = true;
    });

    try {
      final email = await api.findAccount(name: name, phone: phone);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('회원정보를 찾았습니다.'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가입된 메일주소', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '비밀번호는 현재 확인(변경)할 수 없습니다.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Dcolor.homeTextColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.statusCode == 404 ? '일치하는 회원정보를 찾을 수 없습니다.' : '서버에 연결할 수 없습니다.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dcolor.stickerOrange,
      appBar: AppBar(
        backgroundColor: Dcolor.stickerOrange,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('회원정보 찾기'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '가입한 이름을 입력해주세요.',
                style: TextStyle(
                  color: Dcolor.defaultText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              LoginTextField(
                controller: nameController,
                hintText: '이름',
                keyboardType: TextInputType.name,
                height: 45,
                fontSize: 16,
              ),
              const SizedBox(height: 15),
              Text(
                '가입한 핸드폰번호를 입력해주세요.',
                style: TextStyle(
                  color: Dcolor.defaultText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              LoginTextField(
                controller: phoneController,
                hintText: '핸드폰번호',
                keyboardType: TextInputType.phone,
                formatAsPhoneNumber: true,
                height: 45,
                fontSize: 16,
              ),
              const SizedBox(height: 30),
              LoginButton(
                label: isSearching ? '찾는 중...' : '확인',
                onPressed: isSearching ? null : _findAccount,
                backgroundColor: Colors.black,
                height: 52,
                fontSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
