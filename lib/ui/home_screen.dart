import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_app/core/constants/app_constants.dart';
import 'package:qr_app/core/constants/app_colors.dart';

const double kDefaultPadding = 20.0;
const double kGridSpacing = 16.0;
const double kMenuButtonHeight = 190.0;

class User {
  const User({
    required this.name,
    required this.role,
    required this.profileImagePath,
  });

  final String name;
  final String role;
  final String profileImagePath;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _currentUser = User(
    name: 'M. Arkandi S. S.',
    role: 'Fullstack Developer',
    profileImagePath: 'assets/images/profile.png',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserProfileHeader(user: _currentUser),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 20, color: AppColors.textSecondary),
                ),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.qr_code_2,
                              label: 'Create',
                              gradient: AppColors.createGradient,
                              route: '/create',
                              delay: const Duration(milliseconds: 50),
                              height: kMenuButtonHeight,
                            ),
                          ),
                          const SizedBox(width: kGridSpacing),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Scan',
                              gradient: AppColors.scanGradient,
                              route: '/scan',
                              delay: const Duration(milliseconds: 150),
                              height: kMenuButtonHeight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kGridSpacing * 1.5),
                      SizedBox(
                        width: double.infinity,
                        child: _MenuButton(
                          icon: Icons.history,
                          label: 'History',
                          gradient: AppColors.historyGradient,
                          route: '/history',
                          delay: const Duration(milliseconds: 250),
                          width: double.infinity,
                          height: kMenuButtonHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: AssetImage(user.profileImagePath),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.role,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.gradient,
    this.route = '',
    this.delay = Duration.zero,
    this.width,
    this.height,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final String route;
  final Duration delay;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, delay: delay),
        ScaleEffect(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          delay: delay,
        ),
        MoveEffect(begin: const Offset(0, 20), end: Offset.zero, delay: delay),
      ],
      child: GestureDetector(
        onTap: route.isNotEmpty ? () => Navigator.pushNamed(context, route) : null,
        child: SizedBox(
          width: width,
          height: height,
          child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }
}

