// models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String currency;
  final bool isDarkMode;
  final bool pushNotificationsEnabled;
  final bool biometricEnabled;
  final double smallExpensesLimit;
  final String profileImageUrl;
  final double totalSpent;
  final double totalBudget;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.currency,
    required this.isDarkMode,
    required this.pushNotificationsEnabled,
    required this.biometricEnabled,
    required this.smallExpensesLimit,
    required this.profileImageUrl,
    required this.totalSpent,
    required this.totalBudget,
    required this.createdAt,
    this.updatedAt,
  });

  // Default user factory
  factory UserModel.defaultUser() {
    return UserModel(
      id: '',
      email: '',
      fullName: 'User',
      currency: 'RM',
      isDarkMode: false,
      pushNotificationsEnabled: true,
      biometricEnabled: false,
      smallExpensesLimit: 50.0,
      profileImageUrl: '',
      totalSpent: 0.0,
      totalBudget: 0.0,
      createdAt: DateTime.now(),
    );
  }

  // From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName:
          json['full_name'] as String? ?? json['name'] as String? ?? 'User',
      currency: json['currency'] as String? ?? 'RM',
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? true,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      smallExpensesLimit:
          (json['small_expenses_limit'] as num?)?.toDouble() ?? 50.0,
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'currency': currency,
      'is_dark_mode': isDarkMode,
      'push_notifications_enabled': pushNotificationsEnabled,
      'biometric_enabled': biometricEnabled,
      'small_expenses_limit': smallExpensesLimit,
      'profile_image_url': profileImageUrl,
      'total_spent': totalSpent,
      'total_budget': totalBudget,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? currency,
    bool? isDarkMode,
    bool? pushNotificationsEnabled,
    bool? biometricEnabled,
    double? smallExpensesLimit,
    String? profileImageUrl,
    double? totalSpent,
    double? totalBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      currency: currency ?? this.currency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      smallExpensesLimit: smallExpensesLimit ?? this.smallExpensesLimit,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalSpent: totalSpent ?? this.totalSpent,
      totalBudget: totalBudget ?? this.totalBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
