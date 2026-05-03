import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/budget/budget_bloc.dart';
import '../../../logic/blocs/goal/goal_bloc.dart';
import '../../../logic/blocs/transaction/transaction_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = (context.read<AuthBloc>().state as AuthAuthenticated).profile;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data syncs automatically'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              toolbarHeight: 70,
              title: _DashboardHeader(profileName: profile.name),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _BalanceCard().animate().fadeIn().slideY(begin: 0.08),
                  const SizedBox(height: 20),
                  _BudgetOverviewStrip().animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),
                  const SizedBox(height: 20),
                  _TopSpendCard().animate().fadeIn(delay: 160.ms).slideY(begin: 0.08),
                  const SizedBox(height: 20),
                  _RecentTransactions().animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profileName});
  final String profileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                profileName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              () {
                final h = DateTime.now().hour;
                final salutation = h < 12
                    ? 'Good morning'
                    : h < 17
                        ? 'Good afternoon'
                        : 'Good evening';
                return '$salutation, ${profileName.split(' ').first}';
              }(),
              style: AppTypography.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: AppTypography.textTheme.bodySmall,
            ),
          ],
        ),
        const Spacer(),
        Tooltip(
          message: 'Add a new transaction',
          textStyle: const TextStyle(fontSize: 12, color: Colors.white),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          preferBelow: false,
          verticalOffset: 24,
          child: GestureDetector(
            onTap: () => context.push('/add-transaction'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const _NotificationBell(),
      ],
    );
  }
}

class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  static final Set<String> _seenAlerts = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, budgetState) {
        return BlocBuilder<GoalBloc, GoalState>(
          builder: (context, goalState) {
            final currentAlertKeys = <String>[];
            
            for (final b in budgetState.budgets) {
              if (b.isOverBudget) {
                currentAlertKeys.add('budget_over_${b.category}_${b.month}_${b.year}');
              } else if (b.isNearLimit) {
                currentAlertKeys.add('budget_near_${b.category}_${b.month}_${b.year}');
              }
            }
            
            for (final g in goalState.goals) {
              if (g.isCompleted) {
                currentAlertKeys.add('goal_done_${g.id}');
              } else if (g.progressPercent >= 0.8) {
                currentAlertKeys.add('goal_near_${g.id}');
              }
            }

            final unreadCount = currentAlertKeys.where((k) => !_seenAlerts.contains(k)).length;
            final isUnread = unreadCount > 0;

            return Tooltip(
              message: 'Alerts & Notifications',
              textStyle: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              preferBelow: false,
              verticalOffset: 24,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _seenAlerts.addAll(currentAlertKeys);
                  });
                  _showNotificationSheet(context, budgetState, goalState);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(child: Icon(Icons.notifications_outlined, size: 20)),
                      if (isUnread)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.surfaceElevated, width: 2),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.background,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, BudgetState budgetState, GoalState goalState) {
    final alerts = <_NotificationItem>[];

    for (final b in budgetState.budgets) {
      if (b.isOverBudget) {
        alerts.add(_NotificationItem(
          title: '${b.category} Budget Exceeded',
          message: 'You have spent ${CurrencyFormatter.format(b.spentAmount)} (Limit: ${CurrencyFormatter.compact(b.limitAmount)})',
          icon: Icons.warning_amber_rounded,
          color: AppColors.expense,
          route: '/budgets',
        ));
      } else if (b.isNearLimit) {
        alerts.add(_NotificationItem(
          title: '${b.category} Nearing Limit',
          message: 'You have used ${(b.usagePercent * 100).round()}% of your budget.',
          icon: Icons.trending_up_rounded,
          color: AppColors.warning,
          route: '/budgets',
        ));
      }
    }

    for (final g in goalState.goals) {
      if (g.isCompleted) {
        alerts.add(_NotificationItem(
          title: 'Goal Achieved: ${g.title}',
          message: 'You have fully funded this goal!',
          icon: Icons.star_rounded,
          color: AppColors.primary,
          route: '/goals',
        ));
      } else if (g.progressPercent >= 0.8) {
        alerts.add(_NotificationItem(
          title: 'Goal Close: ${g.title}',
          message: 'You are ${(g.progressPercent * 100).round()}% there! Only ${CurrencyFormatter.format(g.remainingAmount)} left.',
          icon: Icons.flag_rounded,
          color: AppColors.secondary,
          route: '/goals',
        ));
      }
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Alerts & Notifications', style: AppTypography.textTheme.titleLarge),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${alerts.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.cardBorder, height: 1),
              if (alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'You\'re all caught up!\nNo active alerts right now.',
                      textAlign: TextAlign.center,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.surfaceElevated, height: 1),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          context.go(alert.route);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: alert.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(alert.icon, color: alert.color, size: 20),
                        ),
                        title: Text(alert.title, style: AppTypography.textTheme.titleMedium),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            alert.message, 
                            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String route;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final net = state.netBalance;
        final income = state.totalIncome;
        final expense = state.totalExpense;

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4A3FBB),
                Color(0xFF7C6FFF),
                Color(0xFF00C49A),
              ],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.5),
                blurRadius: 36,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: net),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => Text(
                  CurrencyFormatter.format(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                net >= 0 ? 'Great financial health!' : 'Expenses exceed income',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'Income',
                      amount: income,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _BalanceStat(
                      label: 'Expenses',
                      amount: expense,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
  });
  final String label;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                CurrencyFormatter.compact(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Budget Overview Strip ─────────────────────────────────────────────────────

class _BudgetOverviewStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state.budgets.isEmpty) return const SizedBox.shrink();
        final overCount = state.overBudgetCount;
        final alertColor = overCount > 0 ? AppColors.expense : AppColors.primary;

        return GestureDetector(
          onTap: () => context.go('/budgets'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: alertColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    overCount > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color: alertColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overCount > 0
                            ? '$overCount budget${overCount > 1 ? 's' : ''} exceeded'
                            : 'All budgets on track',
                        style: AppTypography.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.compact(state.totalSpent)} of ${CurrencyFormatter.compact(state.totalLimit)} spent',
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Top Spend Card ────────────────────────────────────────────────────────────

class _TopSpendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final now = DateTime.now();
        final thisMonthExpenses = state.allTransactions.where(
          (t) =>
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        );
        if (thisMonthExpenses.isEmpty) return const SizedBox.shrink();

        final catTotals = <String, double>{};
        for (final t in thisMonthExpenses) {
          catTotals[t.category] = (catTotals[t.category] ?? 0) + t.amount;
        }
        final topCat =
            catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
        final catColor = AppColors.forCategory(topCat.key);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top spend this month',
                        style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      topCat.key,
                      style: AppTypography.textTheme.titleMedium
                          ?.copyWith(color: catColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.compact(topCat.value),
                style: AppTypography.textTheme.titleLarge?.copyWith(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Recent Transactions ───────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final txns = state.allTransactions.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: AppTypography.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/transactions'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (txns.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No transactions yet',
                subtitle: 'Tap Add to record your first transaction',
                action: () => context.push('/add-transaction'),
                actionLabel: 'Add Transaction',
              )
            else
              ...txns.asMap().entries.map(
                    (e) => _TransactionTile(transaction: e.value)
                        .animate()
                        .fadeIn(delay: (e.key * 60).ms)
                        .slideX(begin: 0.05),
                  ),
          ],
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.forCategory(transaction.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: catColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(
              child: Icon(
                AppIcons.forCategory(transaction.category),
                color: catColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: AppTypography.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.category,
                  style: AppTypography.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount)}',
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: transaction.isExpense
                      ? AppColors.expense
                      : AppColors.income,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMM').format(transaction.date),
                style: AppTypography.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
