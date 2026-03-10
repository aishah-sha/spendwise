import 'package:equatable/equatable.dart';
import '../models/user_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;
  final bool isEditing;

  const ProfileLoaded({required this.user, this.isEditing = false});

  @override
  List<Object?> get props => [user, isEditing];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileLogoutSuccess extends ProfileState {}

class ProfilePasswordChanged extends ProfileState {}

class ProfileThemeChanged extends ProfileState {
  final bool isDarkMode;

  const ProfileThemeChanged({required this.isDarkMode});

  @override
  List<Object?> get props => [isDarkMode];
}
