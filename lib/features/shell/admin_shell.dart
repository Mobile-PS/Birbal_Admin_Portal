import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/routing/admin_destination.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.child, super.key});

  final Widget child;

  int _selectedIndex(String path) {
    final index = adminDestinations.indexWhere((destination) {
      if (destination.path == '/') return path == '/';
      return path == destination.path ||
          path.startsWith('${destination.path}/');
    });
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(path);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 720) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 0,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birbal Advice',
                    style: TextStyle(
                      color: Color(0xFF2F6BFF),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEB5757),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: AppColors.navyDark,
              child: Builder(
                builder: (drawerContext) {
                  return SafeArea(
                    child: AdminSideNav(
                      extended: true,
                      selectedIndex: selected,
                      onSelected: (index) {
                        Scaffold.of(drawerContext).closeDrawer();
                        drawerContext.go(adminDestinations[index].path);
                      },
                    ),
                  );
                },
              ),
            ),
            body: child,
          );
        }

        final extended = width >= 1100;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: extended ? 248 : 80,
                child: AdminSideNav(
                  extended: extended,
                  selectedIndex: selected,
                  onSelected: (index) {
                    context.go(adminDestinations[index].path);
                  },
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

class AdminSideNav extends StatelessWidget {
  const AdminSideNav({
    required this.extended,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandHeader(extended: extended),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: adminDestinations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final destination = adminDestinations[index];
                final selected = index == selectedIndex;
                final tile = _NavTile(
                  key: ValueKey('nav-${destination.path}'),
                  destination: destination,
                  selected: selected,
                  extended: extended,
                  onTap: () => onSelected(index),
                );
                if (extended) return tile;
                return Tooltip(message: destination.label, child: tile);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(extended ? 20 : 12, 24, 12, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'BA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (extended) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birbal Advice',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Admin',
                    style: TextStyle(color: Color(0xFFB7C9D6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
    super.key,
  });

  final AdminDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brand : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: extended ? 12 : 0,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: Colors.white,
                size: 22,
              ),
              if (extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
