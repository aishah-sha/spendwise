// cubit/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile_state.dart';
import '../models/user_model.dart';

class ProfileCubit extends Cubit<ProfileState> {
  static const String _userStorageKey = 'user_data';

  ProfileCubit() : super(ProfileInitial());

  // Load profile from SharedPreferences
  Future<void> loadProfile() async {
    emit(ProfileLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString(_userStorageKey);

      UserModel user;
      if (userJson != null && userJson.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(userJson);
        user = UserModel.fromJson(decoded);
      } else {
        user = UserModel.defaultUser();
        await _saveUser(user);
      }

      emit(ProfileLoaded(user: user, isEditing: false));
    } catch (e) {
      final user = UserModel.defaultUser();
      emit(ProfileLoaded(user: user, isEditing: false));
    }
  }

  // Save user to SharedPreferences
  Future<void> _saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStorageKey, json.encode(user.toJson()));
    } catch (e) {
      // Silent fail
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
    }
  }

  void updateProfileImage(String imageUrl) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(profileImageUrl: imageUrl);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileImageUpdated(imageUrl: imageUrl));
      _saveUser(updatedUser);
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
