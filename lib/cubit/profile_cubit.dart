// cubit/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile_state.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseService _supabaseService = SupabaseService();
  static const String _userStorageKey = 'user_data';
  bool _isLoading = false;

  ProfileCubit() : super(ProfileInitial());

  // Load profile from Supabase (not local storage)
  Future<void> loadProfile() async {
    if (_isLoading) return;
    _isLoading = true;

    emit(ProfileLoading());

    try {
      final profileData = await _supabaseService.getUserProfile();

      if (profileData != null) {
        final user = UserModel.fromJson(profileData);
        // Save to local storage as cache only
        await _saveUser(user);
        emit(ProfileLoaded(user: user, isEditing: false));
      } else {
        // No profile in Supabase, create default
        final defaultUser = UserModel.defaultUser();
        await _saveUser(defaultUser);
        emit(ProfileLoaded(user: defaultUser, isEditing: false));
      }
    } catch (e) {
      // Try to load from local cache as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? userJson = prefs.getString(_userStorageKey);
        if (userJson != null && userJson.isNotEmpty) {
          final Map<String, dynamic> decoded = json.decode(userJson);
          final user = UserModel.fromJson(decoded);
          emit(ProfileLoaded(user: user, isEditing: false));
        } else {
          final defaultUser = UserModel.defaultUser();
          emit(ProfileLoaded(user: defaultUser, isEditing: false));
        }
      } catch (fallbackError) {
        final defaultUser = UserModel.defaultUser();
        emit(ProfileLoaded(user: defaultUser, isEditing: false));
      }
    } finally {
      _isLoading = false;
    }
  }

  // Save user to local SharedPreferences (cache only)
  Future<void> _saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, json.encode(user.toJson()));
    } catch (e) {
      // Silent fail - not critical
    }
  }

  // Public method to save user to Supabase
  Future<void> saveUser(UserModel user) async {
    try {
      await _supabaseService.updateUserProfile(
        fullName: user.fullName,
        currency: user.currency,
        isDarkMode: user.isDarkMode,
        pushNotificationsEnabled: user.pushNotificationsEnabled,
        biometricEnabled: user.biometricEnabled,
        smallExpensesLimit: user.smallExpensesLimit,
        profileImageUrl: user.profileImageUrl,
      );
      await _saveUser(user);
      emit(ProfileLoaded(user: user, isEditing: false));
    } catch (e) {
      emit(ProfileError(message: 'Failed to save profile: ${e.toString()}'));
    }
  }

  void togglePushNotifications() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        pushNotificationsEnabled: !currentState.user.pushNotificationsEnabled,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(
        pushNotificationsEnabled: updatedUser.pushNotificationsEnabled,
      );
    }
  }

  void toggleDarkMode() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        isDarkMode: !currentState.user.isDarkMode,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(isDarkMode: updatedUser.isDarkMode);
    }
  }

  void toggleBiometric() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        biometricEnabled: !currentState.user.biometricEnabled,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(
        biometricEnabled: updatedUser.biometricEnabled,
      );
    }
  }

  void toggleEditMode() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(
        ProfileLoaded(
          user: currentState.user,
          isEditing: !currentState.isEditing,
        ),
      );
    }
  }

  void updateCurrency(String currency) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(currency: currency);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Currency updated to $currency'));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(currency: currency);
    }
  }

  void updateSmallExpensesLimit(double limit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(smallExpensesLimit: limit);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(
        ProfileUpdateSuccess(
          message:
              'Small expenses limit updated to RM${limit.toStringAsFixed(0)}',
        ),
      );
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(smallExpensesLimit: limit);
    }
  }

  void updateProfileImage(String imageUrl) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(profileImageUrl: imageUrl);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileImageUpdated(imageUrl: imageUrl));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(profileImageUrl: imageUrl);
    }
  }

  void updateFullName(String fullName) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      if (fullName.trim().isEmpty) {
        emit(ProfileError(message: 'Full name cannot be empty'));
        return;
      }
      final updatedUser = currentState.user.copyWith(fullName: fullName.trim());
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Full name updated successfully'));
      _saveUser(updatedUser);
      // Update in Supabase
      _supabaseService.updateUserProfile(fullName: fullName.trim());
    }
  }

  void updateEmail(String email) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      if (!email.contains('@') || !email.contains('.')) {
        emit(ProfileError(message: 'Please enter a valid email address'));
        return;
      }
      final updatedUser = currentState.user.copyWith(email: email.trim());
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Email updated successfully'));
      _saveUser(updatedUser);
      // Note: Email update through Supabase requires special handling
      // This might require re-authentication
    }
  }

  void changePassword() {
    emit(ProfilePasswordChanged());
  }

  // Fast clear local profile data - no unnecessary delays
  void clearLocalProfileData() {
    // Fire and forget - don't await
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.remove(_userStorageKey);
        })
        .catchError((e) {
          // Silent fail - not critical
        });
  }

  // Reset to default profile (for testing)
  Future<void> resetToDefault() async {
    final defaultUser = UserModel.defaultUser();
    await _saveUser(defaultUser);
    emit(ProfileLoaded(user: defaultUser, isEditing: false));
    emit(ProfileUpdateSuccess(message: 'Profile reset to default'));
  }

  void clearError() {
    if (state is ProfileError) {
      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(
          ProfileLoaded(
            user: currentState.user,
            isEditing: currentState.isEditing,
          ),
        );
      } else if (state is ProfileInitial) {
        emit(ProfileInitial());
      }
    }
  }

  void clearSuccess() {
    if (state is ProfileUpdateSuccess) {
      if (state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        emit(
          ProfileLoaded(
            user: currentState.user,
            isEditing: currentState.isEditing,
          ),
        );
      }
    }
  }
}
