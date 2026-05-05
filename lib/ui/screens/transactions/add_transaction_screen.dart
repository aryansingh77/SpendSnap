import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/snap_card.dart';
import '../../../core/widgets/snap_text_field.dart';
import '../../../data/models/transaction_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/transaction/transaction_bloc.dart';
import '../../../logic/services/ai_transaction_service.dart';
import 'package:image_picker/image_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.existingTransaction});
  final TransactionModel? existingTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  final TextEditingController _smartEntryCtrl = TextEditingController();

  late TransactionType _type;
  late String _category;

  static const _titleHints = {
    'Food & Dining':    'e.g., Lunch at Swiggy',
    'Transport':        'e.g., Uber to office',
    'Shopping':         'e.g., Clothes from Myntra',
    'Entertainment':    'e.g., Netflix subscription',
    'Health':           'e.g., Apollo pharmacy bill',
    'Bills & Utilities':'e.g., Electricity bill',
    'Other':            'e.g., Stationery purchase',
    'Income':           'e.g., Monthly salary',
    'Savings':          'e.g., FD deposit',
  };
  DateTime _date = DateTime.now();
  late bool _isRecurring;
  late String _recurringInterval;

  @override
  void initState() {
    super.initState();
    final ext = widget.existingTransaction;
    _titleCtrl = TextEditingController(text: ext?.title ?? '');
    _amountCtrl = TextEditingController(text: ext?.amount.toString() ?? '');
    _noteCtrl = TextEditingController(text: ext?.note ?? '');
    _type = ext?.type ?? TransactionType.expense;
    _category = ext?.category ?? (_type == TransactionType.income ? 'Income' : 'Food & Dining');
    _date = ext?.date ?? DateTime.now();
    _isRecurring = ext?.isRecurring ?? false;
    _recurringInterval = ext?.recurringInterval ?? 'Monthly';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _smartEntryCtrl.dispose();
    super.dispose();
  }

  bool _isProcessingAi = false;
  final AiTransactionService _aiService = AiTransactionService();

  Future<void> _processSmartText() async {
    if (_smartEntryCtrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isProcessingAi = true);
    try {
      final uid = (context.read<AuthBloc>().state as AuthAuthenticated).profile.uid;
      final txn = await _aiService.extractFromText(_smartEntryCtrl.text.trim(), uid);
      _populateFromAi(txn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessingAi = false);
    }
  }

  Future<void> _processReceipt() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() => _isProcessingAi = true);
    try {
      final uid = (context.read<AuthBloc>().state as AuthAuthenticated).profile.uid;
      final bytes = await image.readAsBytes();
      final txn = await _aiService.extractFromReceipt(bytes, uid);
      _populateFromAi(txn);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Vision Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessingAi = false);
    }
  }

  void _populateFromAi(TransactionModel txn) {
    setState(() {
      _titleCtrl.text = txn.title;
      _amountCtrl.text = txn.amount.toString();
      _type = txn.type;
      _category = txn.category;
      _date = txn.date;
      _smartEntryCtrl.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Populated successfully from AI!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final uid = (context.read<AuthBloc>().state as AuthAuthenticated).profile.uid;
    final txn = TransactionModel(
      id: widget.existingTransaction?.id ?? const Uuid().v4(),
      userId: uid,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      type: _type,
      category: _type == TransactionType.income ? 'Income' : _category,
      date: _date,
      note: _noteCtrl.text.trim(),
      isRecurring: _isRecurring,
      recurringInterval: _isRecurring ? _recurringInterval : null,
    );
    if (widget.existingTransaction != null) {
      context.read<TransactionBloc>().add(TransactionUpdated(transaction: txn));
    } else {
      context.read<TransactionBloc>().add(TransactionAdded(transaction: txn));
    }
    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existingTransaction != null ? 'Edit Transaction' : 'Add Transaction')),
      body: _isProcessingAi
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Smart Entry Section
              if (widget.existingTransaction == null) ...[
                Text('AI Assistant', style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SnapTextField(
                        controller: _smartEntryCtrl,
                        hint: 'e.g, Spent 500 on dinner',
                        prefixIcon: Icons.auto_awesome_rounded,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 52, // Match text field height
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: _processSmartText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _processReceipt,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Scan Receipt (Camera)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 16),
              ],

              // Type toggle
              _TypeToggle(
                selected: _type,
                onChanged: (t) => setState(() {
                  _type = t;
                  if (t == TransactionType.income) {
                    _category = 'Income';
                  } else {
                    _category = 'Food & Dining';
                  }
                }),
              ),
              const SizedBox(height: 20),
              SnapTextField(
                label: 'Title',
                hint: _titleHints[_category] ?? 'e.g., Salary',
                controller: _titleCtrl,
                prefixIcon: Icons.edit_note_rounded,
                validator: Validators.title,
              ),
              const SizedBox(height: 14),
              SnapTextField(
                label: 'Amount (₹)',
                hint: '0',
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: Validators.amount,
                inputFormatters: [Validators.decimalFormatter],
              ),
              const SizedBox(height: 14),
              if (_type == TransactionType.expense) ...[
                Text('Category', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 8),
                _CategoryGrid(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 14),
              ],
              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: SnapTextField(
                    label: 'Date',
                    controller: TextEditingController(
                        text: DateFormat('d MMM yyyy').format(_date)),
                    prefixIcon: Icons.calendar_today_rounded,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SnapTextField(
                label: 'Note (optional)',
                hint: 'Add a note...',
                controller: _noteCtrl,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Recurring toggle
              SnapCard(
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded,
                        color: AppColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recurring',
                              style: AppTypography.textTheme.titleMedium),
                          if (_isRecurring)
                            DropdownButton<String>(
                              value: _recurringInterval,
                              dropdownColor: AppColors.surface,
                              underline: const SizedBox.shrink(),
                              items: AppConstants.recurringIntervals
                                  .map((i) => DropdownMenuItem(
                                      value: i, child: Text(i)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _recurringInterval = v!),
                            ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRecurring,
                      activeThumbColor: AppColors.secondary,
                      activeTrackColor: AppColors.secondary.withValues(alpha: 0.4),
                      onChanged: (v) => setState(() => _isRecurring = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GlowButton(
                  label: widget.existingTransaction != null ? 'Update Transaction' : 'Save Transaction',
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                  color: _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected, required this.onChanged});
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _Tab(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            selected: selected == TransactionType.expense,
            color: AppColors.expense,
            onTap: () => onChanged(TransactionType.expense),
          )),
          Expanded(child: _Tab(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            selected: selected == TransactionType.income,
            color: AppColors.income,
            onTap: () => onChanged(TransactionType.income),
          )),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: selected ? color : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.expenseCategories.map((cat) {
        final isSelected = cat == selected;
        final color = AppColors.forCategory(cat);
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : AppColors.cardBorder,
              ),
            ),
            child: Text(
              cat,
              style: AppTypography.textTheme.labelMedium?.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
