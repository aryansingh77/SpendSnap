import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/health_score_dial.dart';
import '../../../core/widgets/snap_card.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/blocs/budget/budget_bloc.dart';
import '../../../logic/blocs/transaction/transaction_bloc.dart';
import '../../../logic/services/spending_health_score_service.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (ctx, txState) {
          return BlocBuilder<BudgetBloc, BudgetState>(
            builder: (ctx2, budgetState) {
              final now = DateTime.now();
              final thisMonth = txState.allTransactions
                  .where((t) =>
                      t.date.month == now.month && t.date.year == now.year)
                  .toList();
              final lastMonthDate = DateTime(now.year, now.month - 1);
              final lastMonth = txState.allTransactions
                  .where((t) =>
                      t.date.month == lastMonthDate.month &&
                      t.date.year == lastMonthDate.year)
                  .toList();

              final result =
                  const SpendingHealthScoreService().compute(
                currentMonthTransactions: thisMonth,
                lastMonthTransactions: lastMonth,
                budgets: budgetState.budgets,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                children: [
                  _HealthScoreCard(result: result)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _InsightCards(insights: result.insights)
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _SpendingBreakdownChart(transactions: thisMonth)
                      .animate()
                      .fadeIn(delay: 150.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _MonthlyTrendChart(
                          transactions: txState.allTransactions)
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _ScoreBreakdown(result: result)
                      .animate()
                      .fadeIn(delay: 250.ms)
                      .slideY(begin: 0.1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.result});
  final SpendingHealthResult result;

  @override
  Widget build(BuildContext context) {
    return SnapCard(
      padding: const EdgeInsets.all(20),
      accentColor: result.total >= 75
          ? AppColors.primary
          : result.total >= 50
              ? AppColors.warning
              : AppColors.expense,
      child: Column(
        children: [
          Text('Spending Health Score',
              style: AppTypography.textTheme.titleLarge),
          const SizedBox(height: 16),
          HealthScoreDial(score: result.total),
          const SizedBox(height: 8),
          Text(
            'Score updates with each transaction',
            style: AppTypography.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InsightCards extends StatelessWidget {
  const _InsightCards({required this.insights});
  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Insights', style: AppTypography.textTheme.titleLarge),
        const SizedBox(height: 10),
        ...insights.map((msg) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.secondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(msg,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SpendingBreakdownChart extends StatefulWidget {
  const _SpendingBreakdownChart({required this.transactions});
  final List<TransactionModel> transactions;

  @override
  State<_SpendingBreakdownChart> createState() =>
      _SpendingBreakdownChartState();
}

class _SpendingBreakdownChartState
    extends State<_SpendingBreakdownChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final expenses =
        widget.transactions.where((t) => t.isExpense).toList();
    final catMap = <String, double>{};
    for (final t in expenses) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }
    final total = catMap.values.fold(0.0, (a, b) => a + b);

    if (catMap.isEmpty) {
      return SnapCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('No expense data this month',
                style: AppTypography.textTheme.bodyMedium),
          ),
        ),
      );
    }

    final entries = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((e) {
      final i = e.key;
      final cat = e.value.key;
      final amt = e.value.value;
      final pct = amt / total;
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: amt,
        color: AppColors.forCategory(cat),
        radius: isTouched ? 70 : 58,
        title: pct > 0.08
            ? '${(pct * 100).round()}%'
            : '',
        titleStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

    return SnapCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Breakdown',
              style: AppTypography.textTheme.titleLarge),
          Text(
            'Where your money went this month',
            style: AppTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.touchedSection
                              ?.touchedSectionIndex ??
                          -1;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.forCategory(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key}: ${CurrencyFormatter.compact(e.value)}',
                    style: AppTypography.textTheme.labelMedium,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.transactions});
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    // Build last 6 months of income vs expense
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return d;
    });

    final incomeData = <FlSpot>[];
    final expenseData = <FlSpot>[];

    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final monthTxns = transactions.where((t) =>
          t.date.month == m.month && t.date.year == m.year);
      final income = monthTxns
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTxns
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (s, t) => s + t.amount);
      incomeData.add(FlSpot(i.toDouble(), income));
      expenseData.add(FlSpot(i.toDouble(), expense));
    }

    final allAmounts = [...incomeData, ...expenseData]
        .map((s) => s.y)
        .where((y) => y > 0);
    final maxY = allAmounts.isEmpty
        ? 10000.0
        : allAmounts.reduce((a, b) => a > b ? a : b) * 1.2;

    return SnapCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-Month Trend', style: AppTypography.textTheme.titleLarge),
          Text(
            'Income vs Expenses — spot your patterns',
            style: AppTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.cardBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.compact(v),
                        style: AppTypography.textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('MMM').format(months[idx]),
                          style: AppTypography.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeData,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseData,
                    isCurved: true,
                    color: AppColors.expense,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.expense.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Income'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.expense, label: 'Expenses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.textTheme.labelMedium),
      ],
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.result});
  final SpendingHealthResult result;

  @override
  Widget build(BuildContext context) {
    return SnapCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score Breakdown',
              style: AppTypography.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'How each factor contributes to your health score',
            style: AppTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _ScoreRow(
              label: 'Budget Adherence',
              score: result.budgetScore,
              max: 40,
              icon: Icons.account_balance_wallet_outlined),
          _ScoreRow(
              label: 'Savings Rate',
              score: result.savingsScore,
              max: 30,
              icon: Icons.savings_outlined),
          _ScoreRow(
              label: 'Spending Trend',
              score: result.trendScore,
              max: 20,
              icon: Icons.trending_down_rounded),
          _ScoreRow(
              label: 'Category Diversity',
              score: result.diversityScore,
              max: 10,
              icon: Icons.pie_chart_outline_rounded),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.score,
    required this.max,
    required this.icon,
  });
  final String label;
  final int score;
  final int max;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final pct = score / max;
    final color = pct >= 0.75
        ? AppColors.primary
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTypography.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textPrimary)),
              ),
              Text('$score / $max',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
