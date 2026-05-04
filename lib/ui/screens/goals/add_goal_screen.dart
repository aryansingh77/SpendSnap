import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/snap_text_field.dart';
import '../../../data/models/goal_model.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/goal/goal_bloc.dart';

class AddGoalScreen extends StatefulWidget {
  final GoalModel? existingGoal;

  const AddGoalScreen({super.key, this.existingGoal});
  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  Color _selectedColor = AppColors.secondary;

  bool get _isEditing => widget.existingGoal != null;

  static const _palette = [
    AppColors.secondary,
    AppColors.primary,
    AppColors.expense,
    AppColors.warning,
    Color(0xFFE91E8C),
    Color(0xFF00B4D8),
    Color(0xFF80B918),
    Color(0xFFFF6F00),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.existingGoal!.title;
      _amountCtrl.text = widget.existingGoal!.targetAmount.toString();
      _noteCtrl.text = widget.existingGoal!.note;
      _deadline = widget.existingGoal!.deadline;
      _selectedColor = Color(int.parse(widget.existingGoal!.colorHex));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final uid =
        (context.read<AuthBloc>().state as AuthAuthenticated).profile.uid;

    if (_isEditing) {
      final updatedGoal = widget.existingGoal!.copyWith(
        title: _titleCtrl.text.trim(),
        targetAmount: double.parse(_amountCtrl.text.trim()),
        deadline: _deadline,
        colorHex: _selectedColor.toARGB32().toString(),
        note: _noteCtrl.text.trim(),
      );
      context.read<GoalBloc>().add(GoalUpdated(goal: updatedGoal));
    } else {
      final goal = GoalModel(
        id: const Uuid().v4(),
        userId: uid,
        title: _titleCtrl.text.trim(),
        targetAmount: double.parse(_amountCtrl.text.trim()),
        currentAmount: 0,
        deadline: _deadline,
        colorHex: _selectedColor.toARGB32().toString(),
        note: _noteCtrl.text.trim(),
      );
      context.read<GoalBloc>().add(GoalAdded(goal: goal));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Goal' : 'New Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SnapTextField(
                label: 'Goal Name',
                hint: 'e.g., Emergency Fund',
                controller: _titleCtrl,
                prefixIcon: Icons.flag_outlined,
                validator: Validators.title,
              ),
              const SizedBox(height: 14),
              SnapTextField(
                label: 'Target Amount (₹)',
                hint: '100000',
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee_rounded,
                validator: Validators.amount,
                inputFormatters: [Validators.decimalFormatter],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDeadline,
                child: AbsorbPointer(
                  child: SnapTextField(
                    label: 'Deadline',
                    controller: TextEditingController(
                        text: DateFormat('d MMM yyyy').format(_deadline)),
                    prefixIcon: Icons.calendar_today_rounded,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SnapTextField(
                label: 'Note (optional)',
                hint: 'Why this goal matters...',
                controller: _noteCtrl,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Goal Color',
                  style: AppTypography.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: _palette.map((c) {
                  final isSelected = c == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 10),
                      width: isSelected ? 36 : 30,
                      height: isSelected ? 36 : 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GlowButton(
                  label: _isEditing ? 'Save Changes' : 'Create Goal',
                  onPressed: _submit,
                  icon: Icons.check_rounded,
                  color: _selectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
