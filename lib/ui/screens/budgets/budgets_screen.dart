import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snap_card.dart';
import '../../../data/models/budget_model.dart';
import '../../../logic/blocs/budget/budget_bloc.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/add-budget'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
          ),
        ],
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          if (state.status == BudgetStatus.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state.budgets.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No budgets set',
              subtitle: 'Set monthly limits to track your spending',
              action: () => context.push('/add-budget'),
              actionLabel: 'Create Budget',
            );
          }

          final overCount = state.overBudgetCount;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Summary card
              _SummaryCard(state: state)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.1),
              const SizedBox(height: 16),
              if (overCount > 0)
                _AlertBanner(count: overCount)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideX(begin: -0.05),
              if (overCount > 0) const SizedBox(height: 12),
              Text('This Month',
                  style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 10),
              ...state.budgets.asMap().entries.map(
                    (e) => _BudgetCard(budget: e.value)
                        .animate()
                        .fadeIn(delay: ((e.key + 1) * 80).ms)
                        .slideY(begin: 0.08),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final BudgetState state;

  @override
  Widget build(BuildContext context) {
    final pct = state.totalLimit > 0
        ? (state.totalSpent / state.totalLimit).clamp(0.0, 1.0)
        : 0.0;

    return SnapCard(
      accentColor: pct > 0.9
          ? AppColors.expense
          : pct > 0.7
              ? AppColors.warning
              : AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Budget Usage',
                  style: AppTypography.textTheme.titleMedium),
              Text(
                '${(pct * 100).round()}%',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  color: pct > 0.9
                      ? AppColors.expense
                      : pct > 0.7
                          ? AppColors.warning
                          : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AnimatedBar(progress: pct, height: 10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                  label: 'Spent',
                  value: CurrencyFormatter.compact(state.totalSpent),
                  color: AppColors.expense),
              _Stat(
                  label: 'Remaining',
                  value: CurrencyFormatter.compact(
                      state.totalLimit - state.totalSpent),
                  color: AppColors.primary),
              _Stat(
                  label: 'Total',
                  value: CurrencyFormatter.compact(state.totalLimit),
                  color: AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.textTheme.titleMedium?.copyWith(color: color)),
        Text(label, style: AppTypography.textTheme.labelSmall),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.expense, size: 18),
          const SizedBox(width: 10),
          Text(
            '$count budget${count > 1 ? 's' : ''} exceeded this month',
            style: AppTypography.textTheme.bodyMedium
                ?.copyWith(color: AppColors.expense),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});
  final BudgetModel budget;

  Color _barColor() {
    if (budget.isOverBudget) return AppColors.expense;
    if (budget.isNearLimit) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/add-budget', extra: budget),
      child: SnapCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CategoryBadge(category: budget.category),
                if (budget.isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.expenseMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Over budget',
                        style: AppTypography.textTheme.labelSmall
                            ?.copyWith(color: AppColors.expense)),
                  )
                else if (budget.isNearLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Near limit',
                        style: AppTypography.textTheme.labelSmall
                            ?.copyWith(color: AppColors.warning)),
                  ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') {
                      context.push('/add-budget', extra: budget);
                    } else if (v == 'delete') {
                      context.read<BudgetBloc>().add(BudgetDeleted(
                            userId: budget.userId,
                            budgetId: budget.id,
                          ));
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(budget.spentAmount),
                  style: AppTypography.textTheme.headlineSmall
                      ?.copyWith(color: _barColor()),
                ),
                Text(
                  '/ ${CurrencyFormatter.format(budget.limitAmount)}',
                  style: AppTypography.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AnimatedBar(progress: budget.usagePercent, color: _barColor()),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                budget.isOverBudget
                    ? '${CurrencyFormatter.format(budget.spentAmount - budget.limitAmount)} over'
                    : '${CurrencyFormatter.format(budget.remainingAmount)} left',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: _barColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBar extends StatefulWidget {
  const _AnimatedBar({required this.progress, this.height = 8, this.color});
  final double progress;
  final double height;
  final Color? color;

  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: _anim.value, end: widget.progress).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor = widget.color ??
        (widget.progress > 0.9
            ? AppColors.expense
            : widget.progress > 0.7
                ? AppColors.warning
                : AppColors.primary);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.height),
        child: LinearProgressIndicator(
          value: _anim.value,
          minHeight: widget.height,
          backgroundColor: AppColors.cardBorder,
          valueColor: AlwaysStoppedAnimation(barColor),
        ),
      ),
    );
  }
}
