// widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/notification_cubit.dart';
import '../screens/notification_screen.dart';

class NotificationBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.icon = Icons.notifications,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => NotificationCubit(),
                  child: const NotificationScreen(),
                ),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: iconSize),
              if (state.unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      state.unreadCount > 9 ? '9+' : '${state.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
