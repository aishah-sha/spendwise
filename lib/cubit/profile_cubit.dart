import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_state.dart';
import '../models/user_model.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  void loadProfile() async {
    emit(ProfileLoading());

    try {
      // Simulate loading user data
      await Future.delayed(const Duration(milliseconds: 800));

      final user = UserModel(
        fullName: 'John Matthew',
        email: 'john@gmail.com',
        currency: 'RM',
        pushNotificationsEnabled: false,
        isDarkMode: false,
        profileImageUrl: 'https://i.pravatar.cc/300?u=john',
        smallExpensesLimit: 50.0,
        biometricEnabled: false,
      );

      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(message: 'Failed to load profile'));
    }
  }

  void togglePushNotifications() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        pushNotificationsEnabled: !currentState.user.pushNotificationsEnabled,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
    }
  }

  void toggleDarkMode() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        isDarkMode: !currentState.user.isDarkMode,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
      emit(ProfileThemeChanged(isDarkMode: updatedUser.isDarkMode));
    }
  }

  void toggleBiometric() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(
        biometricEnabled: !currentState.user.biometricEnabled,
      );
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
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
    }
  }

  void updateSmallExpensesLimit(double limit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(smallExpensesLimit: limit);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
    }
  }

  void updateProfileImage(String imageUrl) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(profileImageUrl: imageUrl);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
    }
  }

  void updateFullName(String fullName) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      final updatedUser = currentState.user.copyWith(fullName: fullName);
      emit(ProfileLoaded(user: updatedUser, isEditing: currentState.isEditing));
    }
  }

  void changePassword() {
    emit(ProfilePasswordChanged());
  }

  void logout() async {
    emit(ProfileLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      emit(ProfileLogoutSuccess());
    } catch (e) {
      emit(ProfileError(message: 'Failed to logout'));
    }
  }
}
