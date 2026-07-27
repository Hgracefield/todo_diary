import 'package:flutter/material.dart';
import 'package:my_todo_list_app/api/api_exception.dart';
import 'package:my_todo_list_app/api/rest_api_service.dart';
import 'package:my_todo_list_app/model/server/user.dart';
import 'package:my_todo_list_app/storage/session_storage.dart';
import 'package:my_todo_list_app/util/dcolor.dart';
import 'package:my_todo_list_app/view/login/korea_city_options.dart';
import 'package:my_todo_list_app/view/login/widgets/login_button.dart';
import 'package:my_todo_list_app/view/login/widgets/login_text_field.dart';
import 'package:table_calendar/table_calendar.dart';

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  static const List<String> _emailDomains = [
    '@naver.com',
    '@gmail.com',
    '@daum.net',
    '@kakao.com',
    '@hanmail.net',
  ];
  static const String _customEmailDomain = '직접 입력';

  final api = RestApiService();
  final emailController = TextEditingController();
  final customEmailDomainController = TextEditingController();
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
  String selectedEmailDomain = _emailDomains.first;
  bool obscurePassword = true;
  bool obscurePasswordConfirm = true;

  String get _email {
    final emailId = emailController.text.trim();
    final domain = selectedEmailDomain == _customEmailDomain
        ? customEmailDomainController.text.trim()
        : selectedEmailDomain;
    if (domain.isEmpty) return emailId;
    return '$emailId${domain.startsWith('@') ? domain : '@$domain'}';
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(_refreshFormState);
    customEmailDomainController.addListener(_refreshFormState);
    passwordController.addListener(_refreshFormState);
    passwordConfirmController.addListener(_refreshFormState);
    phoneController.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    emailController.removeListener(_refreshFormState);
    customEmailDomainController.removeListener(_refreshFormState);
    passwordController.removeListener(_refreshFormState);
    passwordConfirmController.removeListener(_refreshFormState);
    phoneController.removeListener(_refreshFormState);
    emailController.dispose();
    customEmailDomainController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    birthDateController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _refreshFormState() {
    if (emailStatusText != null && _email != checkedEmail) {
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
    final emailId = emailController.text.trim();
    final customDomain = customEmailDomainController.text.trim();
    if (emailId.isEmpty) {
      setState(() {
        isEmailAvailable = false;
        emailStatusText = '메일주소의 아이디를 입력해주세요.';
      });
      return;
    }
    if (selectedEmailDomain == _customEmailDomain && customDomain.isEmpty) {
      setState(() {
        isEmailAvailable = false;
        emailStatusText = '메일 도메인을 입력해주세요.';
      });
      return;
    }

    final email = _email;
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
    final pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _BirthDatePickerDialog(
          initialDate: DateTime(now.year - 20, now.month, now.day),
          firstDate: DateTime(1900),
          lastDate: now,
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
    if (isEmailAvailable != true || checkedEmail != _email) {
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
          userEmail: _email,
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
        foregroundColor: Dcolor.defaultText,
        title: Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignEmailField(
                label: '메일주소',
                emailIdController: emailController,
                customDomainController: customEmailDomainController,
                selectedDomain: selectedEmailDomain,
                domains: _emailDomains,
                customDomainValue: _customEmailDomain,
                onDomainChanged: (domain) {
                  if (domain == null) return;
                  setState(() {
                    selectedEmailDomain = domain;
                  });
                  _refreshFormState();
                },
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
                obscureText: obscurePassword,
                suffixIcon: _PasswordVisibilityButton(
                  isObscured: obscurePassword,
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
              _SignField(
                label: '비밀번호 확인',
                hintText: '비밀번호를 다시 입력',
                controller: passwordConfirmController,
                obscureText: obscurePasswordConfirm,
                suffixIcon: _PasswordVisibilityButton(
                  isObscured: obscurePasswordConfirm,
                  onPressed: () {
                    setState(() {
                      obscurePasswordConfirm = !obscurePasswordConfirm;
                    });
                  },
                ),
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

class _BirthDatePickerDialog extends StatefulWidget {
  const _BirthDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_BirthDatePickerDialog> createState() => _BirthDatePickerDialogState();
}

class _BirthDatePickerDialogState extends State<_BirthDatePickerDialog> {
  late DateTime selectedDate;
  late DateTime focusedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    focusedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final datePickerTheme = Theme.of(context).datePickerTheme;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: Dcolor.stickerGreen,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
              child: Text(
                '${selectedDate.year}년 '
                '${selectedDate.month}월 ${selectedDate.day}일',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _canMoveToPreviousMonth
                            ? () => _moveMonth(-1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _pickYear,
                          child: Text(
                            '${focusedDate.year}년 ${focusedDate.month}월',
                            style: TextStyle(
                              color: Dcolor.defaultText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _canMoveToNextMonth
                            ? () => _moveMonth(1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  TableCalendar(
                    locale: 'ko_KR',
                    firstDay: widget.firstDate,
                    lastDay: widget.lastDate,
                    focusedDay: focusedDate,
                    headerVisible: false,
                    rowHeight: 40,
                    daysOfWeekHeight: 28,
                    sixWeekMonthsEnforced: true,
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDate = selected;
                        focusedDate = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        focusedDate = focused;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: true,
                      cellMargin: EdgeInsets.all(4),
                    ),
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        const labels = ['일', '월', '화', '수', '목', '금', '토'];
                        return Center(
                          child: Text(
                            labels[day.weekday % 7],
                            style: TextStyle(
                              color: day.weekday == DateTime.sunday
                                  ? Dcolor.stickerRed
                                  : Dcolor.defaultText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focused) {
                        return _BirthDateCell(day: day);
                      },
                      outsideBuilder: (context, day, focused) {
                        return _BirthDateCell(day: day, isOutside: true);
                      },
                      selectedBuilder: (context, day, focused) {
                        return _BirthDateCell(day: day, isSelected: true);
                      },
                      todayBuilder: (context, day, focused) {
                        return _BirthDateCell(day: day, isToday: true);
                      },
                      disabledBuilder: (context, day, focused) {
                        return _BirthDateCell(day: day, isDisabled: true);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: datePickerTheme.cancelButtonStyle,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: datePickerTheme.confirmButtonStyle,
                    onPressed: () => Navigator.pop(context, selectedDate),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canMoveToPreviousMonth {
    final previousMonth = DateTime(focusedDate.year, focusedDate.month - 1);
    return !previousMonth.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    );
  }

  bool get _canMoveToNextMonth {
    final nextMonth = DateTime(focusedDate.year, focusedDate.month + 1);
    return !nextMonth.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month),
    );
  }

  void _moveMonth(int offset) {
    setState(() {
      focusedDate = DateTime(focusedDate.year, focusedDate.month + offset);
    });
  }

  Future<void> _pickYear() async {
    final pickedYear = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: 320,
            height: 360,
            child: YearPicker(
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              selectedDate: focusedDate,
              onChanged: (date) => Navigator.pop(context, date),
            ),
          ),
        );
      },
    );

    if (pickedYear == null || !mounted) return;
    setState(() {
      focusedDate = DateTime(pickedYear.year, focusedDate.month);
    });
  }
}

class _BirthDateCell extends StatelessWidget {
  const _BirthDateCell({
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.isOutside = false,
    this.isDisabled = false,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isOutside;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final isSunday = day.weekday == DateTime.sunday;
    final textColor = isSunday
        ? Dcolor.stickerRed
        : isDisabled || isOutside
        ? const Color(0xFFB8B8B8)
        : Dcolor.defaultText;

    return Center(
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Dcolor.stickerGreen : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(color: Dcolor.stickerGreen)
              : null,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

class _SignEmailField extends StatelessWidget {
  const _SignEmailField({
    required this.label,
    required this.emailIdController,
    required this.customDomainController,
    required this.selectedDomain,
    required this.domains,
    required this.customDomainValue,
    required this.onDomainChanged,
    required this.trailing,
    this.statusText,
    this.statusColor,
  });

  final String label;
  final TextEditingController emailIdController;
  final TextEditingController customDomainController;
  final String selectedDomain;
  final List<String> domains;
  final String customDomainValue;
  final ValueChanged<String?> onDomainChanged;
  final Widget trailing;
  final String? statusText;
  final Color? statusColor;

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
                flex: 6,
                child: LoginTextField(
                  controller: emailIdController,
                  hintText: '아이디',
                  keyboardType: TextInputType.emailAddress,
                  height: 45,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: selectedDomain == customDomainValue
                    ? _CustomEmailDomainField(
                        controller: customDomainController,
                        domains: domains,
                        onDomainSelected: onDomainChanged,
                      )
                    : _EmailDomainDropdown(
                        value: selectedDomain,
                        domains: domains,
                        customDomainValue: customDomainValue,
                        onChanged: onDomainChanged,
                      ),
              ),
              const SizedBox(width: 8),
              trailing,
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

class _EmailDomainDropdown extends StatelessWidget {
  const _EmailDomainDropdown({
    required this.value,
    required this.domains,
    required this.customDomainValue,
    required this.onChanged,
  });

  final String value;
  final List<String> domains;
  final String customDomainValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 280,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFFA3D1C6),
        ),
        decoration: _emailDomainDecoration(),
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        items: [
          ...domains.map(
            (domain) => DropdownMenuItem<String>(
              value: domain,
              child: Text(domain, overflow: TextOverflow.ellipsis),
            ),
          ),
          DropdownMenuItem<String>(
            value: customDomainValue,
            child: Text(customDomainValue, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _CustomEmailDomainField extends StatelessWidget {
  const _CustomEmailDomainField({
    required this.controller,
    required this.domains,
    required this.onDomainSelected,
  });

  final TextEditingController controller;
  final List<String> domains;
  final ValueChanged<String?> onDomainSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        decoration: _emailDomainDecoration().copyWith(
          hintText: '직접 입력',
          hintStyle: const TextStyle(
            color: Color(0xFFDADADA),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixText: '@',
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            tooltip: '메일 도메인 선택',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFA3D1C6),
            ),
            onSelected: onDomainSelected,
            itemBuilder: (context) => domains
                .map(
                  (domain) =>
                      PopupMenuItem<String>(value: domain, child: Text(domain)),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

InputDecoration _emailDomainDecoration() {
  return InputDecoration(
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
  );
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
    this.suffixIcon,
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
  final Widget? suffixIcon;

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
                  suffixIcon: suffixIcon,
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

class _PasswordVisibilityButton extends StatelessWidget {
  const _PasswordVisibilityButton({
    required this.isObscured,
    required this.onPressed,
  });

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: isObscured ? '비밀번호 보기' : '비밀번호 숨기기',
      icon: Icon(
        isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFFA3D1C6),
        size: 21,
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
