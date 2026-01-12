import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const double kDefaultPadding = 20.0;
const double kGridSpacing = 16.0;

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
        title: const Text('QR S&G'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 640
                  ? 3
                  : 2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserProfileHeader(user: _currentUser),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const Text(
                  'QR S&G',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: kGridSpacing,
                    crossAxisSpacing: kGridSpacing,
                    childAspectRatio: 1.0,
                    children: const [
                      _MenuButton(
                        icon: Icons.qr_code_2,
                        label: 'Create',
                        color: Colors.blueAccent,
                        route: '/create',
                        delay: const Duration(milliseconds: 50),
                      ),
                      _MenuButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan',
                        color: Colors.redAccent,
                        route: '/scan',
                        delay: const Duration(milliseconds: 150),
                      ),
                      _MenuButton(
                        icon: Icons.send,
                        label: 'Share',
                        color: Colors.greenAccent,
                        route: '',
                        delay: const Duration(milliseconds: 250),
                      ),
                      _MenuButton(
                        icon: Icons.print,
                        label: 'Print',
                        color: Colors.purpleAccent,
                        route: '',
                        delay: const Duration(milliseconds: 350),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
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
    required this.color,
    required this.route,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final Duration delay;

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
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
