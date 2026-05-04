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
  final double totalSpent;
  final double totalBudget;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.currency = 'RM',
    this.pushNotificationsEnabled = true,
    this.isDarkMode = false,
    this.profileImageUrl = '',
    this.smallExpensesLimit = 50.0,
    this.biometricEnabled = false,
    this.totalSpent = 0.0,
    this.totalBudget = 0.0,
  });

  // Factory method for default user
  factory UserModel.defaultUser() {
    return UserModel(
      id: '',
      fullName: 'John Matthew',
      email: 'john@gmail.com',
      currency: 'RM',
      pushNotificationsEnabled: true,
      isDarkMode: false,
      profileImageUrl: 'https://i.pravatar.cc/300?u=john',
      smallExpensesLimit: 50.0,
      biometricEnabled: false,
      totalSpent: 0.0,
      totalBudget: 0.0,
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
    double? totalSpent,
    double? totalBudget,
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
      totalSpent: totalSpent ?? this.totalSpent,
      totalBudget: totalBudget ?? this.totalBudget,
    );
  }

  // Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'name': fullName, // For compatibility with the database
      'email': email,
      'currency': currency,
      'push_notifications_enabled': pushNotificationsEnabled,
      'is_dark_mode': isDarkMode,
      'profile_image_url': profileImageUrl,
      'small_expenses_limit': smallExpensesLimit,
      'biometric_enabled': biometricEnabled,
      'total_spent': totalSpent,
      'total_budget': totalBudget,
    };
  }

  // Create from Supabase JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String,
      currency: json['currency'] as String? ?? 'RM',
      pushNotificationsEnabled:
          json['push_notifications_enabled'] as bool? ?? true,
      isDarkMode: json['is_dark_mode'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      smallExpensesLimit:
          (json['small_expenses_limit'] as num?)?.toDouble() ?? 50.0,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
