class UserModel {
  final String fullName;
  final String email;
  final String currency;
  final bool pushNotificationsEnabled;
  final bool isDarkMode;
  final String profileImageUrl;
  final double smallExpensesLimit;
  final bool biometricEnabled;

  UserModel({
    required this.fullName,
    required this.email,
    this.currency = 'RM',
    this.pushNotificationsEnabled = false,
    this.isDarkMode = false,
    this.profileImageUrl = '',
    this.smallExpensesLimit = 50.0,
    this.biometricEnabled = false,
  });

  UserModel copyWith({
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
}
