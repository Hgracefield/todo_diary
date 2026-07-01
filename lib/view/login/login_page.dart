import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/view/login/find_password_page.dart';
import 'package:my_todo_list_app/view/login/sign_page.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';
import 'package:my_todo_list_app/view/tab_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const List<String> _defaultEmailDomains = [
    '@naver.com',
    '@gmail.com',
    '@daum.net',
    '@kakao.com',
    '@hanmail.net',
  ];

  final api = RestApiService();
  final emailIdController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  List<String> emailHistory = [];
  String selectedEmailDomain = _defaultEmailDomains.first;

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(_refreshEmailSuggestions);
    _loadEmailHistory();
  }

  @override
  void dispose() {
    emailFocusNode.removeListener(_refreshEmailSuggestions);
    emailFocusNode.dispose();
    emailIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadEmailHistory() async {
    final history = await SessionStorage.emailHistory();
    if (!mounted) return;
    setState(() {
      emailHistory = history;
      final recentDomain = history.isEmpty
          ? null
          : _domainFromEmail(history.first);
      if (recentDomain != null) {
        selectedEmailDomain = recentDomain;
      }
    });
  }

  void _refreshEmailSuggestions() {
    if (!mounted) return;
    setState(() {});
  }

  List<String> get _visibleEmailSuggestions {
    if (!emailFocusNode.hasFocus) return [];
    final query = _emailId.toLowerCase();
    if (query.isEmpty) return emailHistory;
    return emailHistory
        .where((email) => email.toLowerCase().contains(query))
        .toList();
  }

  List<String> get _emailDomains {
    final historyDomains = emailHistory
        .map(_domainFromEmail)
        .whereType<String>()
        .where((domain) => domain.isNotEmpty);
    return {
      ..._defaultEmailDomains,
      if (selectedEmailDomain.isNotEmpty) selectedEmailDomain,
      ...historyDomains,
    }.toList();
  }

  String get _email {
    final domain = selectedEmailDomain.startsWith('@')
        ? selectedEmailDomain
        : '@$selectedEmailDomain';
    return '$_emailId$domain';
  }

  String get _emailId {
    final value = emailIdController.text.trim();
    final atIndex = value.indexOf('@');
    return atIndex < 0 ? value : value.substring(0, atIndex);
  }

  Future<void> _login() async {
    final emailId = _emailId;
    final email = _email;
    final password = passwordController.text;
    if (emailId.isEmpty || password.isEmpty) {
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
        MaterialPageRoute(builder: (context) => const TabBarPage()),
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
                  _SplitEmailField(
                    controller: emailIdController,
                    focusNode: emailFocusNode,
                    selectedDomain: selectedEmailDomain,
                    domains: _emailDomains,
                    height: fieldHeight,
                    fontSize: fieldFontSize,
                    onIdChanged: _handleEmailIdChanged,
                    onDomainChanged: (domain) {
                      if (domain == null) return;
                      setState(() {
                        selectedEmailDomain = domain;
                      });
                    },
                  ),
                  _EmailSuggestionList(
                    emails: _visibleEmailSuggestions,
                    onSelected: (email) {
                      _selectEmailSuggestion(email);
                      FocusScope.of(context).unfocus();
                    },
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

  void _selectEmailSuggestion(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) {
      emailIdController.text = email;
      emailIdController.selection = TextSelection.collapsed(
        offset: email.length,
      );
      return;
    }

    final id = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    final domains = _emailDomains;
    emailIdController.text = id;
    emailIdController.selection = TextSelection.collapsed(offset: id.length);
    setState(() {
      selectedEmailDomain = domains.contains(domain)
          ? domain
          : _defaultEmailDomains.first;
    });
  }

  void _handleEmailIdChanged(String value) {
    final atIndex = value.indexOf('@');
    if (atIndex > 0 && atIndex < value.length - 1) {
      final id = value.substring(0, atIndex);
      final domain = value.substring(atIndex);
      emailIdController.text = id;
      emailIdController.selection = TextSelection.collapsed(offset: id.length);
      setState(() {
        selectedEmailDomain = domain;
      });
      return;
    }

    _refreshEmailSuggestions();
  }

  static String? _domainFromEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex < 0 || atIndex == email.length - 1) return null;
    return email.substring(atIndex);
  }
}

class _SplitEmailField extends StatelessWidget {
  const _SplitEmailField({
    required this.controller,
    required this.focusNode,
    required this.selectedDomain,
    required this.domains,
    required this.height,
    required this.fontSize,
    required this.onIdChanged,
    required this.onDomainChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String selectedDomain;
  final List<String> domains;
  final double height;
  final double fontSize;
  final ValueChanged<String> onIdChanged;
  final ValueChanged<String?> onDomainChanged;

  @override
  Widget build(BuildContext context) {
    final dropdownValue = domains.contains(selectedDomain)
        ? selectedDomain
        : domains.first;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: LoginTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: '아이디',
              keyboardType: TextInputType.emailAddress,
              onChanged: onIdChanged,
              height: height,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: _EmailDomainDropdown(
              value: dropdownValue,
              domains: domains,
              height: height,
              fontSize: fontSize,
              onChanged: onDomainChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailDomainDropdown extends StatelessWidget {
  const _EmailDomainDropdown({
    required this.value,
    required this.domains,
    required this.height,
    required this.fontSize,
    required this.onChanged,
  });

  final String value;
  final List<String> domains;
  final double height;
  final double fontSize;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 280,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFA3D1C6),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
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
            borderSide: const BorderSide(color: Color(0xFF78BFAE), width: 1.4),
          ),
        ),
        style: TextStyle(
          color: const Color(0xFF333333),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        items: domains
            .map(
              (domain) => DropdownMenuItem<String>(
                value: domain,
                child: Text(domain, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _EmailSuggestionList extends StatelessWidget {
  const _EmailSuggestionList({required this.emails, required this.onSelected});

  final List<String> emails;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 128),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E8E5)),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: emails.length,
        separatorBuilder: (context, index) {
          return const Divider(height: 1, color: Color(0xFFEAF0EE));
        },
        itemBuilder: (context, index) {
          final email = emails[index];
          return InkWell(
            onTap: () => onSelected(email),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 18,
                    color: Color(0xFFA3D1C6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
