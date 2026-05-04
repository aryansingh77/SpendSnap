import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/snap_text_field.dart';
import '../../../data/models/budget_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/budget/budget_bloc.dart';
import '../../../logic/services/budget_recommendation_service.dart';
import '../../../logic/blocs/transaction/transaction_bloc.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? existingBudget;

  const AddBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String _category = 'Food & Dining';
  List<BudgetRecommendation> _recommendations = [];

  bool get _isEditing => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _amountCtrl.text = widget.existingBudget!.limitAmount.toString();
      _category = widget.existingBudget!.category;
    }
    _computeRecommendations();
  }

  void _computeRecommendations() {
    final profile =
        (context.read<AuthBloc>().state as AuthAuthenticated).profile;
    final txns = context.read<TransactionBloc>().state.allTransactions;

    final recs = const BudgetRecommendationService().recommend(
      monthlyIncome: profile.monthlyIncome,
      lastThreeMonthsTransactions: txns,
    );
    setState(() => _recommendations = recs);
  }

  BudgetRecommendation? get _currentRec =>
      _recommendations.where((r) => r.category == _category).isNotEmpty
          ? _recommendations.firstWhere((r) => r.category == _category)
          : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final uid =
        (context.read<AuthBloc>().state as AuthAuthenticated).profile.uid;
    final now = DateTime.now();

    if (_isEditing) {
      final updatedBudget = widget.existingBudget!.copyWith(
        category: _category,
        limitAmount: double.parse(_amountCtrl.text.trim()),
      );
      context.read<BudgetBloc>().add(BudgetUpdated(budget: updatedBudget));
    } else {
      final budget = BudgetModel(
        id: const Uuid().v4(),
        userId: uid,
        category: _category,
        limitAmount: double.parse(_amountCtrl.text.trim()),
        month: now.month,
        year: now.year,
      );
      context.read<BudgetBloc>().add(BudgetAdded(budget: budget));
    }
    context.pop();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = _currentRec;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Budget' : 'New Budget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 10),
              _CategorySelector(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 20),
              SnapTextField(
                label: 'Budget Limit (₹)',
                hint: '5000',
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: Validators.amount,
                inputFormatters: [Validators.decimalFormatter],
              ),
              // Smart recommendation card
              if (rec != null) ...[
                const SizedBox(height: 14),
                _RecommendationCard(
                  rec: rec,
                  onUse: () => _amountCtrl.text =
                      rec.suggestedAmount.toInt().toString(),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GlowButton(
                  label: _isEditing ? 'Save Changes' : 'Create Budget',
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector(
      {required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: AppConstants.expenseCategories
          .map((c) => DropdownMenuItem(
              value: c,
              child: Text(c,
                  style: AppTypography.textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textPrimary))))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec, required this.onUse});
  final BudgetRecommendation rec;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final isOver = rec.isOverspending;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Suggestion: ₹${rec.suggestedAmount.toInt()}',
                  style: AppTypography.textTheme.labelLarge
                      ?.copyWith(color: AppColors.secondary),
                ),
                Text(
                  isOver
                      ? 'You spent ${rec.overspendPercent.round()}% over in recent months'
                      : 'Based on 50/30/20 rule & your history',
                  style: AppTypography.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onUse, child: const Text('Use')),
        ],
      ),
    );
  }
}
