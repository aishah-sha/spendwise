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
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _userStorageKey = 'user_data';
  bool _isLoading = false;

  // Cache the last loaded user
  UserModel? _cachedUser;

  ProfileCubit() : super(ProfileInitial()) {
    // AUTO-LOAD PROFILE WHEN CUBIT IS CREATED
    _autoLoadProfile();
  }

  // Auto-load profile when cubit is created
  Future<void> _autoLoadProfile() async {
    // Small delay to ensure auth is ready
    await Future.delayed(const Duration(milliseconds: 100));
    loadProfile(forceRefresh: false);
  }

  // Fast profile load - shows cached data immediately
  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    // Step 1: Show cached data IMMEDIATELY (if available)
    if (!forceRefresh && _cachedUser != null) {
      emit(ProfileLoaded(user: _cachedUser!, isEditing: false));
      _isLoading = false;
      // Continue to refresh in background
      _refreshProfileInBackground();
      return;
    }

    // Step 2: Try to load from cache quickly
    final cachedUser = await _loadCachedUser();
    if (cachedUser != null && !forceRefresh) {
      _cachedUser = cachedUser;
      emit(ProfileLoaded(user: cachedUser, isEditing: false));
      _isLoading = false;
      // Refresh in background
      _refreshProfileInBackground();
      return;
    }

    // Step 3: No cache, load from network
    await _loadProfileFromNetwork();
    _isLoading = false;
  }

  // Background refresh - doesn't block UI
  Future<void> _refreshProfileInBackground() async {
    try {
      if (!_supabaseService.isUserLoggedIn) {
        return;
      }

      final profileData = await _supabaseService.getUserProfile();
      if (profileData != null && profileData.isNotEmpty) {
        final user = UserModel.fromJson(profileData);
        if (_cachedUser != user) {
          _cachedUser = user;
          await _saveUser(user);
          // Only update UI if still relevant
          if (state is ProfileLoaded) {
            emit(ProfileLoaded(user: user, isEditing: false));
          }
        }
      }
    } catch (e) {
      print('Background refresh failed: $e');
    }
  }

  // Network load with single attempt
  Future<void> _loadProfileFromNetwork() async {
    emit(ProfileLoading());

    try {
      if (!_supabaseService.isUserLoggedIn) {
        emit(ProfileUnauthenticated());
        return;
      }

      final profileData = await _supabaseService.getUserProfile();

      if (profileData != null && profileData.isNotEmpty) {
        final user = UserModel.fromJson(profileData);
        _cachedUser = user;
        await _saveUser(user);
        emit(ProfileLoaded(user: user, isEditing: false));
        print('✅ Profile loaded: ${user.fullName}');
      } else {
        await _createMissingProfile();
      }
    } catch (e) {
      print('Error loading profile: $e');
      await _createMissingProfile();
    }
  }

  // Optimized missing profile creation
  Future<void> _createMissingProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Get name efficiently
        String userName = 'User';

        if (user.userMetadata != null) {
          userName =
              user.userMetadata!['full_name'] ??
              user.userMetadata!['name'] ??
              user.userMetadata!['fullName'] ??
              'User';
        }

        if (userName == 'User' && user.email != null) {
          userName = user.email!.split('@').first;
        }

        print('Creating profile for user: ${user.id}');

        await _supabaseService.createUserProfile(
          userId: user.id,
          email: user.email ?? '',
          name: userName,
        );

        // Single reload after creation
        final profileData = await _supabaseService.getUserProfile();
        if (profileData != null) {
          final newUser = UserModel.fromJson(profileData);
          _cachedUser = newUser;
          await _saveUser(newUser);
          emit(ProfileLoaded(user: newUser, isEditing: false));
        } else {
          final defaultUser = UserModel.defaultUser().copyWith(
            id: user.id,
            email: user.email ?? '',
            fullName: userName,
          );
          _cachedUser = defaultUser;
          await _saveUser(defaultUser);
          emit(ProfileLoaded(user: defaultUser, isEditing: false));
        }
      } else {
        final defaultUser = UserModel.defaultUser();
        _cachedUser = defaultUser;
        emit(ProfileLoaded(user: defaultUser, isEditing: false));
      }
    } catch (e) {
      print('Error creating profile: $e');
      final defaultUser = UserModel.defaultUser();
      _cachedUser = defaultUser;
      emit(ProfileLoaded(user: defaultUser, isEditing: false));
    }
  }

  // Fast cache load - synchronous where possible
  Future<UserModel?> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_userStorageKey);
      if (userJson != null && userJson.isNotEmpty) {
        return UserModel.fromJson(json.decode(userJson));
      }
    } catch (e) {
      print('Error loading cached user: $e');
    }
    return null;
  }

  // Save user (non-blocking)
  Future<void> _saveUser(UserModel user) async {
    _cachedUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, json.encode(user.toJson()));
    } catch (e) {
      // Silent fail
    }
  }

  // All update methods remain the same but with cache update
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
      _cachedUser = user;
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
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
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
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
      _supabaseService.updateUserProfile(isDarkMode: updatedUser.isDarkMode);
    }
  }

  void toggleBiometric() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        biometricEnabled: !currentState.user.biometricEnabled,
      );
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      _saveUser(updatedUser);
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
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Currency updated to $currency'));
      _saveUser(updatedUser);
      _supabaseService.updateUserProfile(currency: currency);
    }
  }

  void updateSmallExpensesLimit(double limit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(smallExpensesLimit: limit);
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(
        ProfileUpdateSuccess(
          message:
              'Small expenses limit updated to RM${limit.toStringAsFixed(0)}',
        ),
      );
      _saveUser(updatedUser);
      _supabaseService.updateUserProfile(smallExpensesLimit: limit);
    }
  }

  void updateProfileImage(String imageUrl) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(profileImageUrl: imageUrl);
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileImageUpdated(imageUrl: imageUrl));
      _saveUser(updatedUser);
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
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Full name updated successfully'));
      _saveUser(updatedUser);
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
      _cachedUser = updatedUser;
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileUpdateSuccess(message: 'Email updated successfully'));
      _saveUser(updatedUser);
    }
  }

  void changePassword() {
    emit(ProfilePasswordChanged());
  }

  void clearLocalProfileData() {
    _cachedUser = null;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_userStorageKey))
        .catchError((e) {});
  }

  Future<void> resetToDefault() async {
    final defaultUser = UserModel.defaultUser();
    _cachedUser = defaultUser;
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

  // Helper method to force refresh profile (useful after login)
  Future<void> forceRefreshProfile() async {
    await loadProfile(forceRefresh: true);
  }
}
