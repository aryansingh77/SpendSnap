import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: AppColors.textMuted),
                  selectedIcon:
                      Icon(Icons.home_rounded, color: AppColors.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined,
                      color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.textMuted),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded,
                      color: AppColors.primary),
                  label: 'Budgets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.flag_outlined, color: AppColors.textMuted),
                  selectedIcon:
                      Icon(Icons.flag_rounded, color: AppColors.primary),
                  label: 'Goals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined,
                      color: AppColors.textMuted),
                  selectedIcon:
                      Icon(Icons.insights_rounded, color: AppColors.primary),
                  label: 'Insights',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
