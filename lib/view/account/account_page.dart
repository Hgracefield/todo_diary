import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/model/server/user.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/view/login/korea_city_options.dart';
import 'package:my_todo_list_app/view/login/login_page.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';
import 'package:my_todo_list_app/view/report/schedule_report_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final api = RestApiService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final newPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedAddress;
  String? phoneStatusText;
  bool? isPhoneAvailable;
  String? checkedPhone;
  String savedPassword = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_refreshPhoneState);
    passwordController.addListener(_refreshPasswordState);
    newPasswordController.addListener(_refreshPasswordState);
    passwordConfirmController.addListener(_refreshPasswordState);
    _loadProfile();
  }

  @override
  void dispose() {
    phoneController.removeListener(_refreshPhoneState);
    passwordController.removeListener(_refreshPasswordState);
    newPasswordController.removeListener(_refreshPasswordState);
    passwordConfirmController.removeListener(_refreshPasswordState);
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    newPasswordController.dispose();
    nameController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    var profile = await SessionStorage.loadProfile();
    if (profile.userId != null) {
      try {
        final user = await api.getUser(profile.userId!);
        profile = AccountProfile(
          userId: user.userId,
          email: user.userEmail,
          password: profile.password,
          name: user.userName,
          birthDate: user.userBirthDate ?? '',
          phone: user.userPhone ?? '',
          address: user.userAddress,
        );
        await SessionStorage.saveProfile(profile);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      emailController.text = profile.email;
      nameController.text = profile.name;
      birthDateController.text = profile.birthDate;
      phoneController.text = profile.phone;
      selectedAddress = profile.address;
      savedPassword = profile.password;
      isLoading = false;
    });
  }

  void _refreshPhoneState() {
    if (phoneStatusText != null &&
        phoneController.text.trim() != checkedPhone) {
      phoneStatusText = null;
      isPhoneAvailable = null;
      checkedPhone = null;
    }
    setState(() {});
  }

  void _refreshPasswordState() {
    if (!mounted) return;
    if (!_isCurrentPasswordValid &&
        (newPasswordController.text.isNotEmpty ||
            passwordConfirmController.text.isNotEmpty)) {
      newPasswordController.clear();
      passwordConfirmController.clear();
    }
    setState(() {});
  }

  bool get _isCurrentPasswordValid {
    return passwordController.text.isNotEmpty &&
        passwordController.text == savedPassword;
  }

  bool get _isPasswordConfirmed {
    final password = newPasswordController.text;
    final confirm = passwordConfirmController.text;
    return password.isNotEmpty && confirm.isNotEmpty && password == confirm;
  }

  String? get _passwordStatusText {
    final password = newPasswordController.text;
    final confirm = passwordConfirmController.text;
    if (password.isEmpty && confirm.isEmpty) return null;
    if (confirm.isEmpty) return null;
    if (_isPasswordConfirmed) return '새 비밀번호가 동일합니다.';
    return '새 비밀번호가 다릅니다.';
  }

  Color get _passwordStatusColor {
    return _isPasswordConfirmed
        ? const Color(0xFF2E9B65)
        : const Color(0xFFE44848);
  }

  void _checkPhoneDuplicate() {
    final phone = phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        isPhoneAvailable = false;
        phoneStatusText = '핸드폰번호를 입력해주세요.';
      } else {
        isPhoneAvailable = true;
        checkedPhone = phone;
        phoneStatusText = '사용 가능한 핸드폰번호입니다.';
      }
    });
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

  Future<void> _saveProfile() async {
    final oldProfile = await SessionStorage.loadProfile();
    final currentPassword = passwordController.text;
    final newPassword = newPasswordController.text;
    final passwordConfirm = passwordConfirmController.text;
    final wantsPasswordChange =
        currentPassword.isNotEmpty ||
        newPassword.isNotEmpty ||
        passwordConfirm.isNotEmpty;

    if (wantsPasswordChange && !_isCurrentPasswordValid) {
      _showMessage('원래 비밀번호가 일치하지 않습니다.');
      return;
    }

    if (wantsPasswordChange && !_isPasswordConfirmed) {
      _showMessage('새 비밀번호와 새 비밀번호 확인이 일치하지 않습니다.');
      return;
    }

    final profile = AccountProfile(
      userId: oldProfile.userId,
      email: emailController.text.trim(),
      password: wantsPasswordChange ? newPassword : oldProfile.password,
      name: nameController.text.trim(),
      birthDate: birthDateController.text.trim(),
      phone: phoneController.text.trim(),
      address: selectedAddress,
    );

    if (profile.userId != null) {
      try {
        final birthDate = profile.birthDate.replaceAll('.', '-');
        await api.updateUser(
          profile.userId!,
          User(
            userId: profile.userId,
            userName: profile.name,
            userBirthDate: birthDate.isEmpty ? null : birthDate,
            userEmail: profile.email,
            userPassword: wantsPasswordChange ? profile.password : null,
            userPhone: profile.phone,
            userAddress: profile.address,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        _showMessage('서버에 계정 정보를 저장하지 못했습니다.');
        return;
      }
    }
    await SessionStorage.saveProfile(profile);
    if (!mounted) return;
    savedPassword = profile.password;
    passwordController.clear();
    passwordConfirmController.clear();
    newPasswordController.clear();
    _showMessage('계정 정보가 저장되었습니다.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    await SessionStorage.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  void _openScheduleReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleReportPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDF2F1),
        elevation: 0,
        foregroundColor: const Color(0xFFA3D1C6),
        title: const Text('내 계정', style: TextStyle(color: Color(0xFF222222))),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccountField(
                      label: '메일주소',
                      hintText: '메일주소',
                      controller: emailController,
                      readOnly: true,
                      textColor: Color(0xFF999999),
                    ),
                    _AccountField(
                      label: '비밀번호 (변경을 원하면 원래 비밀번호를 입력해주세요)',
                      hintText: '원래 비밀번호를 입력',
                      controller: passwordController,
                      obscureText: true,
                    ),
                    _AccountField(
                      label: '새 비밀번호',
                      hintText: '새 비밀번호를 입력',
                      controller: newPasswordController,
                      obscureText: true,
                      enabled: _isCurrentPasswordValid,
                    ),
                    _AccountField(
                      label: '새 비밀번호 확인',
                      hintText: '새 비밀번호를 다시 입력',
                      controller: passwordConfirmController,
                      obscureText: true,
                      enabled: _isCurrentPasswordValid,
                      statusText: _passwordStatusText,
                      statusColor: _passwordStatusColor,
                    ),
                    const SizedBox(height: 18),
                    _AccountField(
                      label: '이름',
                      hintText: '홍길동',
                      controller: nameController,
                    ),
                    _AccountField(
                      label: '생년월일',
                      hintText: '생년월일을 선택해주세요',
                      controller: birthDateController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                    ),
                    _AccountField(
                      label: '핸드폰번호',
                      hintText: '010-1234-5678',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      trailing: _SmallButton(
                        label: '중복확인',
                        onPressed: _checkPhoneDuplicate,
                      ),
                      statusText: phoneStatusText,
                      statusColor: isPhoneAvailable == true
                          ? const Color(0xFF2E9B65)
                          : const Color(0xFFE44848),
                    ),
                    _AccountCityPicker(
                      value: selectedAddress,
                      onChanged: (value) {
                        setState(() {
                          selectedAddress = value;
                        });
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: LoginButton(
                            label: '뒤로가기',
                            onPressed: _goBack,
                            backgroundColor: const Color(0xFFA3D1C6),
                            height: 52,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LoginButton(
                            label: '저장',
                            onPressed: _saveProfile,
                            backgroundColor: const Color(0xFFE67E22),
                            height: 52,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LoginButton(
                      label: '일정 리포트',
                      onPressed: _openScheduleReport,
                      backgroundColor: const Color(0xFF2D9CFF),
                      height: 52,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 12),
                    LoginButton(
                      label: '로그아웃',
                      onPressed: _logout,
                      backgroundColor: const Color(0xFF222222),
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

class _AccountField extends StatelessWidget {
  const _AccountField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.statusText,
    this.statusColor,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textColor,
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
  final bool enabled;
  final VoidCallback? onTap;
  final Color? textColor;

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
                  enabled: enabled,
                  onTap: onTap,
                  textColor: textColor,
                  height: 45,
                  fontSize: 16,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: 5),
            Text(
              statusText!,
              style: TextStyle(
                color: statusColor ?? const Color(0xFF333333),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountCityPicker extends StatelessWidget {
  const _AccountCityPicker({required this.value, required this.onChanged});

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
            '집주소',
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

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onPressed});

  final String label;
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
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
