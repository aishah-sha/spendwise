import 'package:flutter/material.dart';

/// Handles rendering an in-app non-blocking floating card over any active screen view.
/// This remains visible if you switch screens and vanishes automatically.
class InAppNotificationOverlay {
  static OverlayEntry? _currentEntry;

  /// Spawns a top floating over-limit warning notification card that auto-dismisses.
  static void showOverLimit(
    BuildContext context, {
    required String category,
    required double spent,
    required double limit,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Clean up any old notifications still hanging around
    dismiss();

    final overlayState = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          // Safely positioning below typical status bars/notches
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, val, child) {
              return Transform.translate(
                offset: Offset(0, -30 * (1 - val)),
                child: Opacity(opacity: val, child: child),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // 1. Red Alert Circle
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // 2. Main Description Layout Strings
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Budget Limit Exceeded!",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Your spending in '$category' has reached RM ${spent.toStringAsFixed(2)}, passing your RM ${limit.toStringAsFixed(2)} target.",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Close dismiss execution
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => dismiss(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_currentEntry!);

    // Start a background concurrent non-blocking delay timer loop to clear the card
    Future.delayed(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    if (_currentEntry != null) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}
