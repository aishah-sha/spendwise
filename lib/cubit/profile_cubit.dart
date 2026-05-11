// cubit/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile_state.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client; // ← ADD THIS
  static const String _userStorageKey = 'user_data';
  bool _isLoading = false;

  ProfileCubit() : super(ProfileInitial());

  // Load profile from Supabase (not local storage)
  Future<void> loadProfile() async {
    if (_isLoading) return;
    _isLoading = true;

    emit(ProfileLoading());

    try {
      // Check if user is logged in
      if (!_supabaseService.isUserLoggedIn) {
        emit(ProfileUnauthenticated());
        _isLoading = false;
        return;
      }

      final profileData = await _supabaseService.getUserProfile();

      if (profileData != null && profileData.isNotEmpty) {
        final user = UserModel.fromJson(profileData);
        print('✅ Profile loaded: ${user.fullName}');
        await _saveUser(user);
        emit(ProfileLoaded(user: user, isEditing: false));
      } else {
        // No profile in Supabase - CREATE IT IMMEDIATELY
        print('⚠️ No profile found, creating one...');
        await _createMissingProfile();
      }
    } catch (e) {
      print('Error loading profile: $e');

      // Try to load from local cache as fallback
      try {
        final cachedUser = await _loadCachedUser();
        if (cachedUser != null && cachedUser.id.isNotEmpty) {
          emit(ProfileLoaded(user: cachedUser, isEditing: false));
        } else {
          // Create default but try to get user info from auth
          await _createMissingProfile();
        }
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        await _createMissingProfile();
      }
    } finally {
      _isLoading = false;
    }
  }

  // Helper to load cached user
  Future<UserModel?> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_userStorageKey);
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(userJson);
        return UserModel.fromJson(decoded);
      }
    } catch (e) {
      print('Error loading cached user: $e');
    }
    return null;
  }

  // Create missing profile
  Future<void> _createMissingProfile() async {
    try {
      final user = _supabase.auth.currentUser; // ← Now works with _supabase
      if (user != null) {
        // Get name from various sources
        String userName = 'User';

        // Try to get from user metadata
        if (user.userMetadata != null) {
          userName =
              user.userMetadata!['full_name'] ??
              user.userMetadata!['name'] ??
              user.userMetadata!['fullName'] ??
              'User';
        }

        // If still default, try to get from email
        if (userName == 'User' && user.email != null) {
          userName = user.email!.split('@').first;
        }

        print('Creating profile for user: ${user.id} with name: $userName');

        await _supabaseService.createUserProfile(
          userId: user.id,
          email: user.email ?? '',
          name: userName,
        );

        // Reload profile after creation
        final profileData = await _supabaseService.getUserProfile();
        if (profileData != null) {
          final newUser = UserModel.fromJson(profileData);
          await _saveUser(newUser);
          emit(ProfileLoaded(user: newUser, isEditing: false));
          print('✅ Profile created and loaded successfully');
        } else {
          // Still no profile? Create default
          final defaultUser = UserModel.defaultUser().copyWith(
            id: user.id,
            email: user.email ?? '',
            fullName: userName,
          );
          await _saveUser(defaultUser);
          emit(ProfileLoaded(user: defaultUser, isEditing: false));
        }
      } else {
        // No user logged in
        final defaultUser = UserModel.defaultUser();
        emit(ProfileLoaded(user: defaultUser, isEditing: false));
      }
    } catch (e) {
      print('Error creating missing profile: $e');
      final defaultUser = UserModel.defaultUser();
      emit(ProfileLoaded(user: defaultUser, isEditing: false));
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
      emit(ProfileUpdateSuccess(message: 'Profile saved successfully'));
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
