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

  static const List<_MenuItem> _menuItems = [
    _MenuItem(
      icon: Icons.qr_code_2,
      label: 'Create',
      color: Colors.blueAccent,
      route: '/create',
      delay: Duration(milliseconds: 50),
    ),
    _MenuItem(
      icon: Icons.qr_code_scanner,
      label: 'Scan',
      color: Colors.redAccent,
      route: '/scan',
      delay: Duration(milliseconds: 150),
    ),
    _MenuItem(
      icon: Icons.history,
      label: 'History',
      color: Colors.greenAccent,
      route: '/history',
      delay: Duration(milliseconds: 250),
    ),
  ];

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
      body: Padding(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildMenuRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuRows() {
    final rows = <Widget>[];
    for (var i = 0; i < _menuItems.length; i += 2) {
      final chunk = _menuItems.sublist(i, i + 2 <= _menuItems.length ? i + 2 : _menuItems.length);
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: kGridSpacing / 2),
          child: _MenuRow(items: chunk),
        ),
      );
    }
    return rows;
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

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final isSingle = items.length == 1;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0 && !isSingle) {
        children.add(const SizedBox(width: kGridSpacing));
      }
      final button = _MenuButton(
        icon: items[i].icon,
        label: items[i].label,
        color: items[i].color,
        route: items[i].route,
        delay: items[i].delay,
      );
      children.add(isSingle
          ? SizedBox(width: 240, child: button)
          : Expanded(child: button));
    }

    return Row(
      mainAxisAlignment: isSingle ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
      children: children,
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.route = '',
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final Duration delay;
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    this.route = '',
    this.onTap,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final VoidCallback? onTap;
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
        onTap: onTap ?? (route.isNotEmpty ? () => Navigator.pushNamed(context, route) : null),
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

