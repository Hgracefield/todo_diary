import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/util/phone_number_input_formatter.dart';
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
  String originalName = '';
  String originalBirthDate = '';
  String originalPhoneDigits = '';
  String? originalAddress;
  int? currentUserId;
  bool isLoading = true;
  final Set<String> savingFields = <String>{};

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_refreshPhoneState);
    passwordController.addListener(_refreshPasswordState);
    newPasswordController.addListener(_refreshPasswordState);
    passwordConfirmController.addListener(_refreshPasswordState);
    nameController.addListener(_refreshFieldState);
    birthDateController.addListener(_refreshFieldState);
    _loadProfile();
  }

  @override
  void dispose() {
    phoneController.removeListener(_refreshPhoneState);
    passwordController.removeListener(_refreshPasswordState);
    newPasswordController.removeListener(_refreshPasswordState);
    passwordConfirmController.removeListener(_refreshPasswordState);
    nameController.removeListener(_refreshFieldState);
    birthDateController.removeListener(_refreshFieldState);
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
      phoneController.text = formatPhoneNumber(profile.phone);
      originalName = profile.name;
      originalBirthDate = profile.birthDate;
      originalPhoneDigits = phoneNumberDigits(profile.phone);
      selectedAddress = profile.address;
      originalAddress = profile.address;
      currentUserId = profile.userId;
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
    setState(() {});
  }

  void _refreshFieldState() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isPasswordConfirmed {
    final password = newPasswordController.text;
    final confirm = passwordConfirmController.text;
    return password.isNotEmpty && confirm.isNotEmpty && password == confirm;
  }

  bool get _canChangePassword {
    return !savingFields.contains('password') &&
        passwordController.text.isNotEmpty &&
        _isPasswordConfirmed;
  }

  bool get _canChangeName {
    final name = nameController.text.trim();
    return !savingFields.contains('name') &&
        name.isNotEmpty &&
        name != originalName;
  }

  bool get _canChangeBirthDate {
    final birthDate = birthDateController.text.trim();
    return !savingFields.contains('birthDate') &&
        birthDate.isNotEmpty &&
        birthDate != originalBirthDate;
  }

  bool get _canChangePhone {
    final phoneDigits = phoneNumberDigits(phoneController.text);
    if (phoneDigits.isEmpty) return false;
    if (phoneDigits == originalPhoneDigits) return false;

    return !savingFields.contains('phone') &&
        isPhoneAvailable == true &&
        checkedPhone != null &&
        phoneNumberDigits(checkedPhone!) == phoneDigits;
  }

  bool get _canChangeAddress {
    return !savingFields.contains('address') &&
        selectedAddress != null &&
        selectedAddress != originalAddress;
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

  Future<void> _checkPhoneDuplicate() async {
    final phone = phoneController.text.trim();
    final phoneDigits = phoneNumberDigits(phone);
    if (phoneDigits.isEmpty) {
      setState(() {
        isPhoneAvailable = false;
        phoneStatusText = '핸드폰번호를 입력해주세요.';
      });
      return;
    }

    if (phoneDigits == originalPhoneDigits) {
      setState(() {
        isPhoneAvailable = true;
        checkedPhone = phone;
        phoneStatusText = '현재 사용 중인 핸드폰번호입니다.';
      });
      return;
    }

    try {
      final available = await api.isPhoneAvailable(
        phone,
        excludeUserId: currentUserId,
      );
      if (!mounted) return;
      setState(() {
        isPhoneAvailable = available;
        checkedPhone = phone;
        phoneStatusText = available ? '사용 가능한 핸드폰번호입니다.' : '이미 사용 중인 핸드폰번호입니다.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isPhoneAvailable = null;
        checkedPhone = null;
        phoneStatusText = null;
      });
      _showMessage('중복 확인 중 서버에 연결할 수 없습니다.');
    }
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

  Future<void> _changePassword() async {
    if (!_canChangePassword) return;
    final userId = currentUserId;
    if (userId == null) {
      _showMessage('로그인 정보를 확인할 수 없습니다.');
      return;
    }

    final currentPassword = passwordController.text;
    final newPassword = newPasswordController.text;
    setState(() => savingFields.add('password'));
    try {
      await api.updateUserPassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final profile = await SessionStorage.loadProfile();
      await SessionStorage.saveProfile(profile.copyWith(password: newPassword));
      if (!mounted) return;
      passwordController.clear();
      newPasswordController.clear();
      passwordConfirmController.clear();
      _showMessage('비밀번호가 변경되었습니다.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.statusCode == 401 ? '현재 비밀번호가 일치하지 않습니다.' : '비밀번호를 변경하지 못했습니다.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('비밀번호를 변경하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => savingFields.remove('password'));
      }
    }
  }

  Future<void> _changeName() async {
    final name = nameController.text.trim();
    if (!_canChangeName) return;
    await _updateAccountField(
      field: 'name',
      values: {'userName': name},
      updateProfile: (profile) => profile.copyWith(name: name),
      onSaved: () => originalName = name,
      successMessage: '이름이 변경되었습니다.',
    );
  }

  Future<void> _changeBirthDate() async {
    final birthDate = birthDateController.text.trim();
    if (!_canChangeBirthDate) return;
    await _updateAccountField(
      field: 'birthDate',
      values: {'userBirthDate': birthDate.replaceAll('.', '-')},
      updateProfile: (profile) => profile.copyWith(birthDate: birthDate),
      onSaved: () => originalBirthDate = birthDate,
      successMessage: '생년월일이 변경되었습니다.',
    );
  }

  Future<void> _changePhone() async {
    if (!_canChangePhone) return;
    final phone = phoneController.text.trim();
    await _updateAccountField(
      field: 'phone',
      values: {'userPhone': phone},
      updateProfile: (profile) => profile.copyWith(phone: phone),
      onSaved: () {
        originalPhoneDigits = phoneNumberDigits(phone);
        checkedPhone = phone;
        isPhoneAvailable = true;
        phoneStatusText = '현재 사용 중인 핸드폰번호입니다.';
      },
      successMessage: '핸드폰번호가 변경되었습니다.',
      duplicatePhoneMessage: true,
    );
  }

  Future<void> _changeAddress() async {
    final address = selectedAddress;
    if (!_canChangeAddress || address == null) return;
    await _updateAccountField(
      field: 'address',
      values: {'userAddress': address},
      updateProfile: (profile) => profile.copyWith(address: address),
      onSaved: () => originalAddress = address,
      successMessage: '주소가 변경되었습니다.',
    );
  }

  Future<void> _updateAccountField({
    required String field,
    required Map<String, dynamic> values,
    required AccountProfile Function(AccountProfile profile) updateProfile,
    required VoidCallback onSaved,
    required String successMessage,
    bool duplicatePhoneMessage = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      _showMessage('로그인 정보를 확인할 수 없습니다.');
      return;
    }

    setState(() => savingFields.add(field));
    try {
      await api.updateUserFields(userId, values);
      final profile = await SessionStorage.loadProfile();
      await SessionStorage.saveProfile(updateProfile(profile));
      if (!mounted) return;
      setState(onSaved);
      _showMessage(successMessage);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        duplicatePhoneMessage && error.statusCode == 409
            ? '이미 사용 중인 핸드폰번호입니다.'
            : '회원정보를 변경하지 못했습니다.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('회원정보를 변경하지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => savingFields.remove(field));
      }
    }
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
                      label: '현재 비밀번호',
                      hintText: '현재 비밀번호를 입력',
                      controller: passwordController,
                      obscureText: true,
                    ),
                    _AccountField(
                      label: '새 비밀번호',
                      hintText: '새 비밀번호를 입력',
                      controller: newPasswordController,
                      obscureText: true,
                      enabled: passwordController.text.isNotEmpty,
                    ),
                    _AccountField(
                      label: '새 비밀번호 확인',
                      hintText: '새 비밀번호를 다시 입력',
                      controller: passwordConfirmController,
                      obscureText: true,
                      enabled: passwordController.text.isNotEmpty,
                      trailing: _SmallButton(
                        label: '비밀번호 변경',
                        onPressed: _canChangePassword ? _changePassword : null,
                      ),
                      statusText: _passwordStatusText,
                      statusColor: _passwordStatusColor,
                    ),
                    const SizedBox(height: 18),
                    _AccountField(
                      label: '이름',
                      hintText: '홍길동',
                      controller: nameController,
                      trailing: _SmallButton(
                        label: '이름 변경',
                        onPressed: _canChangeName ? _changeName : null,
                      ),
                    ),
                    _AccountField(
                      label: '생년월일',
                      hintText: '생년월일을 선택해주세요',
                      controller: birthDateController,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      trailing: _SmallButton(
                        label: '생년월일 변경',
                        onPressed: _canChangeBirthDate
                            ? _changeBirthDate
                            : null,
                      ),
                    ),
                    _AccountField(
                      label: '핸드폰번호',
                      hintText: '010-1234-5678',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      formatAsPhoneNumber: true,
                      trailing: _SmallButton(
                        label: '중복확인',
                        onPressed: _checkPhoneDuplicate,
                      ),
                      action: _SmallButton(
                        label: '핸드폰번호 변경',
                        onPressed: _canChangePhone ? _changePhone : null,
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
                      trailing: _SmallButton(
                        label: '주소 변경',
                        onPressed: _canChangeAddress ? _changeAddress : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    LoginButton(
                      label: '뒤로가기',
                      onPressed: _goBack,
                      backgroundColor: const Color(0xFFA3D1C6),
                      height: 52,
                      fontSize: 16,
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
    this.formatAsPhoneNumber = false,
    this.action,
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
  final bool formatAsPhoneNumber;
  final Widget? action;

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
                  formatAsPhoneNumber: formatAsPhoneNumber,
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
          if (action != null) ...[
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      ),
    );
  }
}

class _AccountCityPicker extends StatelessWidget {
  const _AccountCityPicker({
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(
                child: SizedBox(
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
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 45,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFA3D1C6),
          disabledBackgroundColor: const Color(0xFFBDBDBD),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
