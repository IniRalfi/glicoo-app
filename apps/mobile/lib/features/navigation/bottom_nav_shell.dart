// bottom_nav_shell.dart
//
// Bottom navigation shell dengan 4 tab:
//   Home, Quests, Bot Hub, Profile
//
// Purpose:
// Main app shell setelah login, handle tab switching.
//
// Used By:
// main.dart (setelah auth berhasil)
//
// Depends On:
// flutter/material, app_colors, flutter_svg, google_fonts
//
// Impact:
// Semua halaman utama aplikasi

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../quests/quests_screen.dart';
import '../bot_hub/bot_hub_screen.dart';
import '../profile/profile_screen.dart';

/// Provider state untuk indeks tab navigasi aktif.
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Shell utama aplikasi dengan bottom navigation bar.
class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const QuestsScreen(),
    const BotHubScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false,
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                indicatorColor: Colors.transparent,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    );
                  }
                  return GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              height: 72,
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              },
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icon/navigation/home.svg',
                    width: 24,
                    height: 24,
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icon/navigation/home-active.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icon/navigation/misi.svg',
                    width: 24,
                    height: 24,
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icon/navigation/misi-aktif.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: 'Misi',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icon/navigation/chatbot.svg',
                    width: 24,
                    height: 24,
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icon/navigation/chatbot-active.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: 'Bot Hub',
                ),
                NavigationDestination(
                  icon: SvgPicture.asset(
                    'assets/icon/navigation/user.svg',
                    width: 24,
                    height: 24,
                  ),
                  selectedIcon: SvgPicture.asset(
                    'assets/icon/navigation/user-active.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

