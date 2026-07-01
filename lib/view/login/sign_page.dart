import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/model/server/user.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/view/login/korea_city_options.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  final api = RestApiService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final nameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();

  String? emailStatusText;
  bool? isEmailAvailable;
  String? checkedEmail;
  String? phoneStatusText;
  bool? isPhoneAvailable;
  String? checkedPhone;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_refreshFormState);
    passwordController.addListener(_refreshFormState);
    passwordConfirmController.addListener(_refreshFormState);
    phoneController.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    emailController.removeListener(_refreshFormState);
    passwordController.removeListener(_refreshFormState);
    passwordConfirmController.removeListener(_refreshFormState);
    phoneController.removeListener(_refreshFormState);
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _refreshFormState() {
    if (emailStatusText != null &&
        emailController.text.trim() != checkedEmail) {
      emailStatusText = null;
      isEmailAvailable = null;
      checkedEmail = null;
    }
    if (phoneStatusText != null &&
        phoneController.text.trim() != checkedPhone) {
      phoneStatusText = null;
      isPhoneAvailable = null;
      checkedPhone = null;
    }
    setState(() {});
  }

  Future<void> _checkEmailDuplicate() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        isEmailAvailable = false;
        emailStatusText = '메일주소를 입력해주세요.';
      });
      return;
    }

    try {
      final available = await api.isEmailAvailable(email);
      if (!mounted) return;
      setState(() {
        isEmailAvailable = available;
        checkedEmail = email;
        emailStatusText = available ? '사용 가능한 메일주소입니다.' : '이미 사용 중인 메일주소입니다.';
      });
    } catch (_) {
      _showMessage('중복 확인 중 서버에 연결할 수 없습니다.');
    }
  }

  Future<void> _checkPhoneDuplicate() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        isPhoneAvailable = false;
        phoneStatusText = '핸드폰번호를 입력해주세요.';
      });
      return;
    }

    try {
      final available = await api.isPhoneAvailable(phone);
      if (!mounted) return;
      setState(() {
        isPhoneAvailable = available;
        checkedPhone = phone;
        phoneStatusText = available ? '사용 가능한 핸드폰번호입니다.' : '이미 사용 중인 핸드폰번호입니다.';
      });
    } catch (_) {
      _showMessage('중복 확인 중 서버에 연결할 수 없습니다.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA3D1C6),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final formattedDate =
        '${pickedDate.year.toString().padLeft(4, '0')}.'
        '${pickedDate.month.toString().padLeft(2, '0')}.'
        '${pickedDate.day.toString().padLeft(2, '0')}';
    setState(() {
      birthDateController.text = formattedDate;
    });
  }

  String? get _passwordStatusText {
    final password = passwordController.text;
    final confirm = passwordConfirmController.text;
    if (confirm.isEmpty) return null;
    if (password == confirm) return '비밀번호가 확인되었습니다.';
    return '비밀번호가 다릅니다.';
  }

  Color get _passwordStatusColor {
    return passwordController.text == passwordConfirmController.text
        ? const Color(0xFF2E9B65)
        : const Color(0xFFE44848);
  }

  Future<void> _saveSignProfile() async {
    if (passwordController.text != passwordConfirmController.text) {
      _showMessage('비밀번호 확인이 일치하지 않습니다.');
      return;
    }
    if (isEmailAvailable != true ||
        checkedEmail != emailController.text.trim()) {
      _showMessage('메일주소 중복 확인을 해주세요.');
      return;
    }
    if (phoneController.text.trim().isNotEmpty &&
        (isPhoneAvailable != true ||
            checkedPhone != phoneController.text.trim())) {
      _showMessage('핸드폰번호 중복 확인을 해주세요.');
      return;
    }

    final birthDate = birthDateController.text.trim().replaceAll('.', '-');
    try {
      final user = await api.createUser(
        User(
          userName: nameController.text.trim(),
          userBirthDate: birthDate.isEmpty ? null : birthDate,
          userEmail: emailController.text.trim(),
          userPassword: passwordController.text,
          userPhone: phoneController.text.trim(),
          userAddress: selectedAddress,
        ),
      );
      await SessionStorage.saveProfile(
        AccountProfile(
          userId: user.userId,
          email: user.userEmail,
          password: passwordController.text,
          name: user.userName,
          birthDate: user.userBirthDate ?? '',
          phone: user.userPhone ?? '',
          address: user.userAddress,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (error) {
      _showMessage(
        error.statusCode == 409 ? '이미 등록된 회원 정보입니다.' : '회원가입에 실패했습니다.',
      );
    } catch (_) {
      _showMessage('서버에 연결할 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDF2F1),
        elevation: 0,
        foregroundColor: const Color(0xFFA3D1C6),
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignField(
                label: '메일주소',
                hintText: 'example@email.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                trailing: _DuplicateCheckButton(
                  onPressed: _checkEmailDuplicate,
                ),
                statusText: emailStatusText,
                statusColor: isEmailAvailable == true
                    ? const Color(0xFF2E9B65)
                    : const Color(0xFFE44848),
              ),
              _SignField(
                label: '비밀번호',
                hintText: '8자 이상 입력',
                controller: passwordController,
                obscureText: true,
              ),
              _SignField(
                label: '비밀번호 확인',
                hintText: '비밀번호를 다시 입력',
                controller: passwordConfirmController,
                obscureText: true,
                statusText: _passwordStatusText,
                statusColor: _passwordStatusColor,
              ),
              _SignField(
                label: '이름',
                hintText: '홍길동',
                controller: nameController,
              ),
              _SignField(
                label: '생년월일',
                hintText: '생년월일을 선택해주세요',
                controller: birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
              ),
              _SignField(
                label: '핸드폰번호',
                hintText: '010-1234-5678',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                trailing: _DuplicateCheckButton(
                  onPressed: _checkPhoneDuplicate,
                ),
                statusText: phoneStatusText,
                statusColor: isPhoneAvailable == true
                    ? const Color(0xFF2E9B65)
                    : const Color(0xFFE44848),
              ),
              _KoreaCityPicker(
                value: selectedAddress,
                onChanged: (value) {
                  setState(() {
                    selectedAddress = value;
                  });
                },
              ),
              const SizedBox(height: 48),
              LoginButton(
                label: '가입하기',
                onPressed: _saveSignProfile,
                backgroundColor: const Color(0xFFE67E22),
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

class _KoreaCityPicker extends StatelessWidget {
  const _KoreaCityPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = value != null && koreaCityOptions.contains(value)
        ? value
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주소',
            style: TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 45,
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue,
              isExpanded: true,
              menuMaxHeight: 320,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFA3D1C6),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: '지역을 선택해주세요',
                hintStyle: const TextStyle(
                  color: Color(0xFFDADADA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF78BFAE),
                    width: 1.4,
                  ),
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              items: koreaCityOptions
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignField extends StatelessWidget {
  const _SignField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.statusText,
    this.statusColor,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final String? statusText;
  final Color? statusColor;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: LoginTextField(
                  controller: controller,
                  hintText: hintText,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  readOnly: readOnly,
                  onTap: onTap,
                  height: 45,
                  fontSize: 16,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: 5),
            _StatusText(text: statusText!, color: statusColor),
          ],
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? const Color(0xFF333333),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _DuplicateCheckButton extends StatelessWidget {
  const _DuplicateCheckButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFA3D1C6),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          '중복확인',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
