// cubit/profile_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'profile_state.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _userStorageKey = 'user_data';
  bool _isLoading = false;
  UserModel? _cachedUser;

  ProfileCubit() : super(ProfileInitial()) {
    _loadProfileDirect();
  }

  // NEW: Direct load - shows UI immediately
  Future<void> _loadProfileDirect() async {
    // Try to load from cache first
    final cachedUser = await _loadCachedUser();
    if (cachedUser != null) {
      _cachedUser = cachedUser;
      emit(ProfileLoaded(user: cachedUser, isEditing: false));
      print('✅ Profile loaded from cache');
    } else {
      // If no cache, create default user immediately
      final defaultUser = UserModel.defaultUser();
      _cachedUser = defaultUser;
      await _saveUser(defaultUser);
      emit(ProfileLoaded(user: defaultUser, isEditing: false));
      print('✅ Default profile created');
    }

    // Then update from network in background (with timeout)
    _updateFromNetwork();
  }

  Future<void> _updateFromNetwork() async {
    try {
      if (!_supabaseService.isUserLoggedIn) return;

      final profileData = await _supabaseService.getUserProfile().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      if (profileData != null &&
          profileData.isNotEmpty &&
          state is ProfileLoaded) {
        final currentState = state as ProfileLoaded;
        final networkUser = UserModel.fromJson(profileData);

        // Preserve local image if it exists
        String finalImageUrl = currentState.user.profileImageUrl;
        if (currentState.user.profileImageUrl.isNotEmpty &&
            currentState.user.hasLocalImage) {
          finalImageUrl = currentState.user.profileImageUrl;
        } else {
          finalImageUrl = networkUser.profileImageUrl;
        }

        final updatedUser = currentState.user.copyWith(
          fullName: networkUser.fullName,
          email: networkUser.email,
          currency: networkUser.currency,
          isDarkMode: networkUser.isDarkMode,
          pushNotificationsEnabled: networkUser.pushNotificationsEnabled,
          totalSpent: networkUser.totalSpent,
          totalBudget: networkUser.totalBudget,
          profileImageUrl: finalImageUrl,
        );

        _cachedUser = updatedUser;
        await _saveUser(updatedUser);
        emit(ProfileLoaded(user: updatedUser, isEditing: false));
        print('✅ Profile updated from network');
      }
    } catch (e) {
      print('Network update failed: $e');
    }
  }

  // Keep existing loadProfile for compatibility
  Future<void> loadProfile({bool forceRefresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;

    final cachedUser = await _loadCachedUser();
    if (cachedUser != null && !forceRefresh) {
      _cachedUser = cachedUser;
      emit(ProfileLoaded(user: cachedUser, isEditing: false));
      _isLoading = false;
      return;
    }

    final defaultUser = UserModel.defaultUser();
    _cachedUser = defaultUser;
    await _saveUser(defaultUser);
    emit(ProfileLoaded(user: defaultUser, isEditing: false));
    _isLoading = false;
  }

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

  Future<void> _saveUser(UserModel user) async {
    _cachedUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, json.encode(user.toJson()));
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  Future<void> updateProfileImage(String imagePath) async {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;

      debugPrint('📸 Updating profile image to: $imagePath');

      // Verify the image exists before updating
      if (imagePath.isNotEmpty) {
        final file = File(imagePath);
        final exists = await file.exists();
        if (!exists) {
          debugPrint('❌ Image file does not exist: $imagePath');
          emit(ProfileError(message: 'Failed to load image'));
          return;
        }
        debugPrint('✅ Image file verified, size: ${await file.length()} bytes');
      }

      final updatedUser = currentState.user.copyWith(
        profileImageUrl: imagePath,
      );

      _cachedUser = updatedUser;
      await _saveUser(updatedUser);

      // Force a complete rebuild by emitting a new state
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));

      if (imagePath.isEmpty) {
        emit(ProfileUpdateSuccess(message: 'Profile photo removed'));
      } else {
        emit(ProfileUpdateSuccess(message: 'Profile photo updated!'));
      }

      // Sync to backend in background
      _supabaseService.updateUserProfile(profileImageUrl: imagePath);
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

  void clearLocalProfileData() {
    _cachedUser = null;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_userStorageKey))
        .catchError((e) {});
  }

  Future<void> forceRefreshProfile() async {
    await _updateFromNetwork();
  }
}
