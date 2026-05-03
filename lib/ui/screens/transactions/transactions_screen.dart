import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/category_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/snap_card.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/blocs/transaction/transaction_bloc.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedCategory;
  TransactionType? _selectedType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: AppTypography.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_selectedCategory != null || _selectedType != null)
            _ActiveFilterBar(
              category: _selectedCategory,
              type: _selectedType,
              onClear: _clearFilter,
            ),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state.status == TransactionStatus.loading) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                final query = _searchQuery.toLowerCase();
                final list = query.isEmpty
                    ? state.filtered
                    : state.filtered
                        .where((t) =>
                            t.title.toLowerCase().contains(query) ||
                            t.category.toLowerCase().contains(query))
                        .toList();
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions',
                    subtitle: _selectedCategory != null || _selectedType != null
                        ? 'Try removing filters'
                        : 'Add your first transaction',
                    action: () => context.push('/add-transaction'),
                    actionLabel: 'Add Transaction',
                  );
                }

                // Group by date
                final grouped = <String, List<TransactionModel>>{};
                for (final t in list) {
                  final key = DateFormat('d MMMM yyyy').format(t.date);
                  grouped.putIfAbsent(key, () => []).add(t);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final key = grouped.keys.elementAt(i);
                    final txns = grouped[key]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(key,
                              style: AppTypography.textTheme.labelLarge
                                  ?.copyWith(
                                      color: AppColors.textSecondary)),
                        ),
                        ...txns.asMap().entries.map(
                              (e) => _TxnTile(txn: e.value)
                                  .animate()
                                  .fadeIn(delay: (e.key * 40).ms)
                                  .slideX(begin: 0.04),
                            ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        selectedCategory: _selectedCategory,
        selectedType: _selectedType,
        onApply: (cat, type) {
          setState(() {
            _selectedCategory = cat;
            _selectedType = type;
          });
          context.read<TransactionBloc>().add(
                TransactionFilterChanged(category: cat, type: type),
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _clearFilter() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
    });
    context
        .read<TransactionBloc>()
        .add(const TransactionFilterChanged());
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});
  final TransactionModel txn;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete Transaction'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.expense))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<TransactionBloc>().add(TransactionDeleted(
              userId: txn.userId,
              transactionId: txn.id,
            ));
      },
      child: SnapCard(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.forCategory(txn.category)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  AppIcons.forCategory(txn.category),
                  color: AppColors.forCategory(txn.category),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.title,
                      style: AppTypography.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      CategoryBadge(category: txn.category, compact: true),
                      if (txn.isRecurring) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.repeat_rounded,
                                  size: 10, color: AppColors.secondary),
                              const SizedBox(width: 3),
                              Text(txn.recurringInterval ?? '',
                                  style: AppTypography.textTheme.labelSmall
                                      ?.copyWith(color: AppColors.secondary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountDisplay(amount: txn.amount, isExpense: txn.isExpense),
                const SizedBox(height: 2),
                Text(DateFormat('h:mm a').format(txn.date),
                    style: AppTypography.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.category,
    required this.type,
    required this.onClear,
  });
  final String? category;
  final TransactionType? type;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.secondary.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            [
              if (category != null) category!,
              if (type != null)
                type == TransactionType.income ? 'Income' : 'Expense',
            ].join(' • '),
            style: AppTypography.textTheme.labelMedium
                ?.copyWith(color: AppColors.secondary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedCategory,
    required this.selectedType,
    required this.onApply,
  });
  final String? selectedCategory;
  final TransactionType? selectedType;
  final void Function(String?, TransactionType?) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _cat;
  late TransactionType? _type;

  @override
  void initState() {
    super.initState();
    _cat = widget.selectedCategory;
    _type = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Transactions',
              style: AppTypography.textTheme.headlineSmall),
          const SizedBox(height: 20),
          Text('Type', style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _TypeChip(
                label: 'All',
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Income',
                selected: _type == TransactionType.income,
                onTap: () => setState(() => _type = TransactionType.income),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Expense',
                selected: _type == TransactionType.expense,
                onTap: () => setState(() => _type = TransactionType.expense),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Category', style: AppTypography.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip(
                label: 'All',
                selected: _cat == null,
                onTap: () => setState(() => _cat = null),
              ),
              ...AppConstants.allCategories.map((c) => _TypeChip(
                    label: c,
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c),
                  )),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_cat, _type),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
