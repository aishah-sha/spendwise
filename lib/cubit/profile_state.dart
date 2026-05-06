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

class ProfileUpdateSuccess extends ProfileState {
  final String message;

  const ProfileUpdateSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileImageUpdated extends ProfileState {
  final String imageUrl;

  const ProfileImageUpdated({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class ProfilePasswordChanged extends ProfileState {}
