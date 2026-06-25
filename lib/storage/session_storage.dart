import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _isLoggedInKey = 'is_logged_in';
  static const _userIdKey = 'account_user_id';
  static const _emailKey = 'account_email';
  static const _passwordKey = 'account_password';
  static const _nameKey = 'account_name';
  static const _birthDateKey = 'account_birth_date';
  static const _phoneKey = 'account_phone';
  static const _addressKey = 'account_address';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> login({
    required int userId,
    required String email,
    required String password,
    String? name,
    String? birthDate,
    String? phone,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
    if (email.isNotEmpty) {
      await prefs.setString(_emailKey, email);
    }
    if (password.isNotEmpty) {
      await prefs.setString(_passwordKey, password);
    }
    if (name != null) await prefs.setString(_nameKey, name);
    if (birthDate != null) await prefs.setString(_birthDateKey, birthDate);
    if (phone != null) await prefs.setString(_phoneKey, phone);
    if (address != null && address.isNotEmpty) {
      await prefs.setString(_addressKey, address);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_birthDateKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_addressKey);
  }

  static Future<int?> userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<AccountProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return AccountProfile(
      userId: prefs.getInt(_userIdKey),
      email: prefs.getString(_emailKey) ?? 'user@example.com',
      password: prefs.getString(_passwordKey) ?? '',
      name: prefs.getString(_nameKey) ?? '',
      birthDate: prefs.getString(_birthDateKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? '',
      address: prefs.getString(_addressKey),
    );
  }

  static Future<void> saveProfile(AccountProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile.userId != null) {
      await prefs.setInt(_userIdKey, profile.userId!);
    }
    await prefs.setString(_emailKey, profile.email);
    await prefs.setString(_passwordKey, profile.password);
    await prefs.setString(_nameKey, profile.name);
    await prefs.setString(_birthDateKey, profile.birthDate);
    await prefs.setString(_phoneKey, profile.phone);
    if (profile.address == null || profile.address!.isEmpty) {
      await prefs.remove(_addressKey);
    } else {
      await prefs.setString(_addressKey, profile.address!);
    }
  }
}

class AccountProfile {
  final int? userId;
  final String email;
  final String password;
  final String name;
  final String birthDate;
  final String phone;
  final String? address;

  const AccountProfile({
    this.userId,
    required this.email,
    required this.password,
    required this.name,
    required this.birthDate,
    required this.phone,
    required this.address,
  });
}
