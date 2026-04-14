// models/user_model.dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String currency;
  final bool pushNotificationsEnabled;
  final bool isDarkMode;
  final String profileImageUrl;
  final double smallExpensesLimit;
  final bool biometricEnabled;

  UserModel({
    this.id = 'user_1',
    required this.fullName,
    required this.email,
    this.currency = 'RM',
    this.pushNotificationsEnabled = false,
    this.isDarkMode = false,
    this.profileImageUrl = '',
    this.smallExpensesLimit = 50.0,
    this.biometricEnabled = false,
  });

  // Factory method for default user
  factory UserModel.defaultUser() {
    return UserModel(
      fullName: 'John Matthew',
      email: 'john@gmail.com',
      currency: 'RM',
      pushNotificationsEnabled: false,
      isDarkMode: false,
      profileImageUrl: 'https://i.pravatar.cc/300?u=john',
      smallExpensesLimit: 50.0,
      biometricEnabled: false,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? currency,
    bool? pushNotificationsEnabled,
    bool? isDarkMode,
    String? profileImageUrl,
    double? smallExpensesLimit,
    bool? biometricEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      smallExpensesLimit: smallExpensesLimit ?? this.smallExpensesLimit,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'currency': currency,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'isDarkMode': isDarkMode,
      'profileImageUrl': profileImageUrl,
      'smallExpensesLimit': smallExpensesLimit,
      'biometricEnabled': biometricEnabled,
    };
  }

  // Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 'user_1',
      fullName: json['fullName'] ?? 'John Matthew',
      email: json['email'] ?? 'john@gmail.com',
      currency: json['currency'] ?? 'RM',
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? false,
      isDarkMode: json['isDarkMode'] ?? false,
      profileImageUrl:
          json['profileImageUrl'] ?? 'https://i.pravatar.cc/300?u=john',
      smallExpensesLimit: (json['smallExpensesLimit'] ?? 50.0).toDouble(),
      biometricEnabled: json['biometricEnabled'] ?? false,
    );
  }
}
