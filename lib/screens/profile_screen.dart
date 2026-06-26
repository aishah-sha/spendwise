import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spendwise/services/image_picker_service.dart';

// Cubits
import '../cubit/budget_cubit.dart';
import '../cubit/expense_cubit.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/auth_cubit.dart' as auth_cubit;

// Screens
import '../widgets/notification_badge.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'expense_history_screen.dart';
import 'add_expense_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color bgColor = Color(0xFFE8F7CB);
  static const Color headerColor = Color(0xFFC5D997);
  static const Color accentGreen = Color(0xFF32BA32);
  static const Color fabBorderColor = Color(0xFFD4E5B0);
  static const Color darkText = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileCubit>().loadProfile();
    });

    return BlocListener<auth_cubit.AuthCubit, auth_cubit.AuthState>(
      listener: (context, state) {
        if (state is auth_cubit.Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          bool isDarkMode = (state is ProfileLoaded)
              ? state.user.isDarkMode
              : false;

          return Theme(
            data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
            child: Scaffold(
              backgroundColor: isDarkMode ? Colors.black : bgColor,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton: _buildFab(context, isDarkMode),
              bottomNavigationBar: _buildBottomNavigation(context, isDarkMode),
              body: Column(
                children: [
                  _buildTopHeader(context, isDarkMode),
                  Expanded(child: _ProfileContent(isDarkMode: isDarkMode)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.only(top: 35, left: 20, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : headerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SpendWise',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : darkText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<ExpenseCubit>(),
                        child: const AnalyticsScreen(),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.bar_chart,
                  size: 28,
                  color: isDarkMode ? Colors.white : darkText,
                ),
              ),
              const SizedBox(width: 15),
              IconTheme(
                data: IconThemeData(
                  color: isDarkMode ? Colors.white : darkText,
                ),
                child: BlocProvider(
                  create: (context) => NotificationCubit(),
                  child: const NotificationBadge(
                    icon: Icons.notifications_none,
                    iconSize: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      height: 70,
      width: 70,
      child: FloatingActionButton(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        elevation: 4,
        shape: const CircleBorder(
          side: BorderSide(color: fabBorderColor, width: 4),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => AddExpenseCubit(),
              child: const AddExpenseScreen(),
            ),
          ),
        ),
        child: Icon(Icons.add, color: accentGreen, size: 45),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, bool isDarkMode) {
    return BottomAppBar(
      color: isDarkMode ? Colors.grey[900] : headerColor,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              Icons.home_outlined,
              Icons.home,
              'Home',
              false,
              isDarkMode,
              () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: BlocProvider.of<ExpenseCubit>(context),
                      child: const DashboardScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.history_outlined,
              Icons.history,
              'History',
              false,
              isDarkMode,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => BlocProvider.value(
                      value: context.read<ExpenseCubit>(),
                      child: const ExpenseHistoryScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 40),
            _navItem(
              Icons.pie_chart_outline,
              Icons.pie_chart,
              'Budget',
              false,
              isDarkMode,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: context.read<ExpenseCubit>()),
                        BlocProvider(create: (context) => BudgetCubit()),
                      ],
                      child: const BudgetScreen(),
                    ),
                  ),
                );
              },
            ),
            _navItem(
              Icons.person_outline,
              Icons.person,
              'Profile',
              true,
              isDarkMode,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    IconData activeIcon,
    String label,
    bool active,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? activeIcon : icon,
            color: active
                ? accentGreen
                : (isDarkMode ? Colors.white70 : Colors.black54),
            size: 26,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active
                  ? accentGreen
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// OPTIMIZED PROFILE IMAGE WIDGET - FAST LOADING
// ============================================================

class ProfileImageWidget extends StatefulWidget {
  final String imageUrl;
  final double radius;
  final bool isDarkMode;

  const ProfileImageWidget({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.isDarkMode,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isImageLoaded = false;

  // FIXED: Track loading state to prevent infinite loops
  bool _isLoadingImage = false;
  String? _lastLoadedUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfileImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // FIXED: Only reload if URL actually changed
    if (oldWidget.imageUrl != widget.imageUrl && widget.imageUrl.isNotEmpty) {
      _isImageLoaded = false;
      _lastLoadedUrl = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final imageUrl = widget.imageUrl;

    // FIXED: Prevent duplicate loads
    if (_isLoadingImage || _lastLoadedUrl == imageUrl) {
      debugPrint('⏭️ Skipping duplicate load for: $imageUrl');
      return;
    }

    debugPrint('🖼️ ProfileImageWidget loading: $imageUrl');

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageProvider = null;
      _isImageLoaded = false;
      _isLoadingImage = true;
    });

    if (imageUrl.isEmpty) {
      debugPrint('📷 Empty URL, showing placeholder');
      setState(() {
        _isLoading = false;
        _isImageLoaded = false;
        _isLoadingImage = false;
        _lastLoadedUrl = '';
      });
      return;
    }

    // Check if image is already cached
    if (ProfileCubit.isImageCached(imageUrl)) {
      debugPrint('📷 Image found in cache: $imageUrl');
      try {
        final file = File(imageUrl);
        if (await file.exists()) {
          if (mounted) {
            setState(() {
              _imageProvider = FileImage(file);
              _isLoading = false;
              _isImageLoaded = true;
              _isLoadingImage = false;
              _lastLoadedUrl = imageUrl;
            });
          }
          debugPrint('✅ Image loaded from cache');
          return;
        } else {
          ProfileCubit.clearImageCache(imageUrl);
        }
      } catch (e) {
        debugPrint('⚠️ Cache load error: $e');
        ProfileCubit.clearImageCache(imageUrl);
      }
    }

    // Try to load from file directly
    try {
      String cleanPath = imageUrl;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.substring(7);
      }

      final file = File(cleanPath);
      final exists = await file.exists();

      debugPrint('📁 File exists: $exists at path: $cleanPath');

      if (exists && mounted) {
        final fileSize = await file.length();
        if (fileSize > 0) {
          ProfileCubit.imageCache[imageUrl] = imageUrl;

          if (mounted) {
            setState(() {
              _imageProvider = FileImage(file);
              _isLoading = false;
              _isImageLoaded = true;
              _isLoadingImage = false;
              _lastLoadedUrl = imageUrl;
            });
          }
          debugPrint('✅ Image loaded successfully, size: $fileSize bytes');
        } else {
          debugPrint('⚠️ File is empty (0 bytes)');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _isImageLoaded = false;
              _isLoadingImage = false;
              _lastLoadedUrl = imageUrl;
            });
          }
        }
      } else {
        debugPrint('⚠️ File not found');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _isImageLoaded = false;
            _isLoadingImage = false;
            _lastLoadedUrl = imageUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _isImageLoaded = false;
          _isLoadingImage = false;
          _lastLoadedUrl = imageUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: widget.radius * 0.4,
            height: widget.radius * 0.4,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF32BA32)),
            ),
          ),
        ),
      );
    }

    if (_imageProvider != null && !_hasError && _isImageLoaded) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.isDarkMode
            ? Colors.grey[800]
            : Colors.grey[300],
        backgroundImage: _imageProvider,
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('❌ Background image error: $exception');
          if (mounted) {
            setState(() {
              _hasError = true;
              _imageProvider = null;
              _isImageLoaded = false;
              if (widget.imageUrl.isNotEmpty) {
                ProfileCubit.clearImageCache(widget.imageUrl);
              }
            });
          }
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
      child: Icon(
        Icons.person,
        size: widget.radius,
        color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[500],
      ),
    );
  }
}

// ============================================================
// PROFILE CONTENT
// ============================================================

class _ProfileContent extends StatelessWidget {
  final bool isDarkMode;

  const _ProfileContent({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }

        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ProfileScreen.accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                _buildProfileHeader(context, state),
                const SizedBox(height: 35),
                _buildSection('PERSONAL INFORMATION', [
                  _buildTile(
                    Icons.person_outline,
                    'Full Name',
                    state.user.fullName,
                  ),
                  _buildTile(Icons.email_outlined, 'Email', state.user.email),
                ]),
                const SizedBox(height: 25),
                _buildSection('PREFERENCES', [
                  _buildSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    value: state.user.pushNotificationsEnabled,
                    onChanged: (value) {
                      context.read<ProfileCubit>().togglePushNotifications();
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    value: state.user.isDarkMode,
                    onChanged: (value) {
                      context.read<ProfileCubit>().toggleDarkMode();
                    },
                  ),
                ]),
                const SizedBox(height: 25),
                _buildSection('EXPENSE SETTINGS', [
                  _buildSmallExpensesLimit(context, state),
                ]),
                const SizedBox(height: 40),
                _buildLogoutButton(context),
                const SizedBox(height: 80),
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: ProfileScreen.accentGreen),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileLoaded state) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImagePickerOptions(context, state),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.grey[600]!
                        : ProfileScreen.fabBorderColor,
                    width: 2,
                  ),
                ),
                child: ProfileImageWidget(
                  key: ValueKey(
                    'profile_image_${state.user.profileImageUrl}_${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  imageUrl: state.user.profileImageUrl,
                  radius: 56,
                  isDarkMode: isDarkMode,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: ProfileScreen.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.user.fullName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          ),
        ),
        Text(
          state.user.email,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showEditProfileSheet(context, state),
          icon: Icon(Icons.edit, size: 18, color: ProfileScreen.accentGreen),
          label: Text(
            "Edit Profile",
            style: TextStyle(color: ProfileScreen.accentGreen),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ProfileScreen.accentGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
        ),
      ],
    );
  }

  // ─── FAST Image Picker with Optimized Size ───────────────────────────────

  Future<void> _showImagePickerOptions(
    BuildContext context,
    ProfileLoaded state,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: ProfileScreen.accentGreen,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImageFromGalleryFast(context, state);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: ProfileScreen.accentGreen,
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImageFromCameraFast(context, state);
                },
              ),
              if (state.user.profileImageUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showRemoveConfirmation(context, state);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // FAST: Pick from gallery with optimized size
  Future<void> _pickImageFromGalleryFast(
    BuildContext context,
    ProfileLoaded state,
  ) async {
    if (!context.mounted) return;

    try {
      final imagePickerService = ImagePickerService();
      final imagePath = await imagePickerService
          .pickProfileImageFromGalleryFast(quality: 50, maxSize: 200);

      if (imagePath != null && context.mounted) {
        context.read<ProfileCubit>().updateProfileImage(imagePath);
      }
    } catch (e) {
      print('❌ Error picking from gallery: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // FAST: Pick from camera with optimized size
  Future<void> _pickImageFromCameraFast(
    BuildContext context,
    ProfileLoaded state,
  ) async {
    if (!context.mounted) return;

    try {
      final imagePickerService = ImagePickerService();
      final imagePath = await imagePickerService.pickProfileImageFromCameraFast(
        quality: 50,
        maxSize: 200,
      );

      if (imagePath != null && context.mounted) {
        context.read<ProfileCubit>().updateProfileImage(imagePath);
      }
    } catch (e) {
      print('❌ Error picking from camera: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to take photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRemoveConfirmation(BuildContext context, ProfileLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileCubit>().updateProfileImage('');
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ProfileScreen.accentGreen, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      activeThumbColor: ProfileScreen.accentGreen,
      onChanged: onChanged,
    );
  }

  Widget _buildSmallExpensesLimit(BuildContext context, ProfileLoaded state) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.money_off,
          color: ProfileScreen.accentGreen,
          size: 20,
        ),
      ),
      title: Text(
        'Small Expenses Limit',
        style: TextStyle(
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Expenses below this amount are considered "small"',
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RM ${state.user.smallExpensesLimit.toStringAsFixed(0)}',
              style: const TextStyle(
                color: ProfileScreen.accentGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _showLimitSlider(context, state);
              },
              child: const Icon(
                Icons.edit,
                size: 16,
                color: ProfileScreen.accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitSlider(BuildContext context, ProfileLoaded state) {
    double currentLimit = state.user.smallExpensesLimit;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Small Expenses Limit",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Set the maximum amount for small expenses",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ProfileScreen.accentGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'RM ${currentLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ProfileScreen.accentGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Slider(
                    value: currentLimit,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: ProfileScreen.accentGreen,
                    inactiveColor: isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey.shade300,
                    onChanged: (value) {
                      setState(() {
                        currentLimit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode
                                ? Colors.white70
                                : Colors.grey,
                            side: BorderSide(
                              color: isDarkMode ? Colors.white70 : Colors.grey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context
                                .read<ProfileCubit>()
                                .updateSmallExpensesLimit(currentLimit);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProfileScreen.accentGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context, ProfileLoaded state) {
    final nameController = TextEditingController(text: state.user.fullName);
    final emailController = TextEditingController(text: state.user.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 15,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
              ),
              const SizedBox(height: 25),
              Stack(
                alignment: Alignment.center,
                children: [
                  ProfileImageWidget(
                    imageUrl: state.user.profileImageUrl,
                    radius: 50,
                    isDarkMode: isDarkMode,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showImagePickerOptions(context, state);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: ProfileScreen.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: ProfileScreen.accentGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey[700]!
                          : ProfileScreen.fabBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey[700]!
                          : ProfileScreen.fabBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: ProfileScreen.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : ProfileScreen.darkText,
                ),
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: ProfileScreen.accentGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey[700]!
                          : ProfileScreen.fabBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.grey[700]!
                          : ProfileScreen.fabBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: ProfileScreen.accentGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text != state.user.fullName) {
                    context.read<ProfileCubit>().updateFullName(
                      nameController.text,
                    );
                  }
                  if (emailController.text != state.user.email) {
                    context.read<ProfileCubit>().updateEmail(
                      emailController.text,
                    );
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileScreen.accentGreen,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey.shade800
                  : ProfileScreen.fabBorderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(isDarkMode ? 0.2 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ProfileScreen.accentGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: ProfileScreen.accentGreen, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isDarkMode ? Colors.white : ProfileScreen.darkText,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context);
        },
        icon: const Icon(Icons.logout, size: 20),
        label: const Text("Log Out"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logging out...'),
                    duration: Duration(milliseconds: 500),
                  ),
                );
                await context.read<auth_cubit.AuthCubit>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}
