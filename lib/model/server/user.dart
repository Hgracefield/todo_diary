class User {
  final int? userId;
  final String userName;
  final String? userBirthDate;
  final String userEmail;
  final String? userPassword;
  final String? userPhone;
  final String? userAddress;
  final String? userCreatedAt;
  final String? userUpdatedAt;

  const User({
    this.userId,
    required this.userName,
    this.userBirthDate,
    required this.userEmail,
    this.userPassword,
    this.userPhone,
    this.userAddress,
    this.userCreatedAt,
    this.userUpdatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? json['USER_ID'],
      userName: json['userName'] ?? json['USER_NAME'] ?? '',
      userBirthDate: json['userBirthDate'] ?? json['USER_BIRTH_DATE'],
      userEmail: json['userEmail'] ?? json['USER_EMAIL'] ?? '',
      userPassword: json['userPassword'] ?? json['USER_PASSWORD'],
      userPhone: json['userPhone'] ?? json['USER_PHONE'],
      userAddress: json['userAddress'] ?? json['USER_ADDRESS'],
      userCreatedAt:
          json['userCreatedAt'] ??
          json['userCreateAt'] ??
          json['USER_CREATE_AT'],
      userUpdatedAt: json['userUpdatedAt'] ?? json['USER_UPDATED_AT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      'userName': userName,
      'userBirthDate': userBirthDate,
      'userEmail': userEmail,
      if (userPassword != null) 'userPassword': userPassword,
      'userPhone': userPhone,
      'userAddress': userAddress,
    };
  }
}
