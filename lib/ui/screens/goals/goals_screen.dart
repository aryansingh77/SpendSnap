import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snap_card.dart';
import '../../../data/models/goal_model.dart';
import '../../../logic/blocs/goal/goal_bloc.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/add-goal'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New'),
          ),
        ],
      ),
      body: BlocBuilder<GoalBloc, GoalState>(
        builder: (context, state) {
          if (state.status == GoalStatus.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state.goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              subtitle: 'Set a savings goal and track your progress',
              action: () => context.push('/add-goal'),
              actionLabel: 'Create Goal',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (state.totalSaved > 0)
                _TotalSavingsCard(
                  saved: state.totalSaved,
                  target: state.totalTarget,
                ).animate().fadeIn().slideY(begin: 0.1),
              if (state.totalSaved > 0) const SizedBox(height: 16),
              if (state.active.isNotEmpty) ...[
                Text('Active Goals',
                    style: AppTypography.textTheme.titleLarge),
                const SizedBox(height: 10),
                ...state.active.asMap().entries.map(
                      (e) => _GoalCard(goal: e.value)
                          .animate()
                          .fadeIn(delay: (e.key * 80).ms)
                          .slideY(begin: 0.08),
                    ),
              ],
              if (state.completed.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Completed',
                    style: AppTypography.textTheme.titleLarge),
                const SizedBox(height: 10),
                ...state.completed.map((g) => _GoalCard(goal: g)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-goal'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TotalSavingsCard extends StatelessWidget {
  const _TotalSavingsCard({required this.saved, required this.target});
  final double saved;
  final double target;

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Saved', style: AppTypography.textTheme.bodyMedium),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: saved),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              CurrencyFormatter.format(v),
              style: AppTypography.textTheme.displayLarge
                  ?.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${CurrencyFormatter.format(target)} across all goals',
            style: AppTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final GoalModel goal;

  Color get _color {
    try {
      return Color(int.parse(goal.colorHex));
    } catch (_) {
      return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/add-goal', extra: goal),
      child: SnapCard(
        margin: const EdgeInsets.only(bottom: 12),
        accentColor: _color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: goal.progressPercent,
                        strokeWidth: 5,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: AlwaysStoppedAnimation(_color),
                      ),
                      Center(
                        child: Text(
                          '${(goal.progressPercent * 100).round()}%',
                          style: TextStyle(
                            color: _color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(goal.title,
                      style: AppTypography.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Completed',
                        style: AppTypography.textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                  )
                else
                  PopupMenuButton<String>(
                    color: AppColors.surfaceElevated,
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    onSelected: (v) {
                      if (v == 'edit') {
                        context.push('/add-goal', extra: goal);
                      } else if (v == 'add-funds') {
                        _showAddFundsSheet(context);
                      } else if (v == 'delete') {
                        context.read<GoalBloc>().add(GoalDeleted(
                              userId: goal.userId,
                              goalId: goal.id,
                            ));
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'add-funds', child: Text('Add Funds')),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved',
                        style: AppTypography.textTheme.labelMedium),
                    Text(
                      CurrencyFormatter.format(goal.currentAmount),
                      style: AppTypography.textTheme.headlineSmall
                          ?.copyWith(color: _color),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target',
                        style: AppTypography.textTheme.labelMedium),
                    Text(
                      CurrencyFormatter.format(goal.targetAmount),
                      style: AppTypography.textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressPercent,
                minHeight: 4,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(_color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.isCompleted
                  ? 'Done!'
                  : goal.isOverdue
                      ? 'Overdue'
                      : '${goal.daysLeft}d left',
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: goal.isOverdue
                    ? AppColors.expense
                    : AppColors.textSecondary,
              ),
            ),
            if (!goal.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Deadline: ${DateFormat('d MMM yyyy').format(goal.deadline)}',
                  style: AppTypography.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddFundsSheet(BuildContext context) {
    // viewPadding.bottom inside extendBody body = system safe area + floating nav bar height
    final navBarInset = MediaQuery.of(context).viewPadding.bottom;
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + navBarInset + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Funds to "${goal.title}"',
                style: AppTypography.textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTypography.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: const Icon(Icons.currency_rupee_rounded,
                    color: AppColors.textMuted, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(ctrl.text.trim());
                  if (amount != null && amount > 0) {
                    context.read<GoalBloc>().add(GoalFundsAdded(
                          userId: goal.userId,
                          goalId: goal.id,
                          amount: amount,
                        ));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Funds'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
