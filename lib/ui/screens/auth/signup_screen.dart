import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/glow_button.dart';
import '../../../core/widgets/snap_text_field.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final income = double.tryParse(_incomeCtrl.text.trim()) ?? 0.0;
    context.read<AuthBloc>().add(AuthSignUpRequested(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      monthlyIncome: income,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Logo().animate().fadeIn(),
                  const SizedBox(height: 28),
                  Text('Create account',
                      style: AppTypography.textTheme.headlineMedium)
                      .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  Text('Start your financial journey today',
                      style: AppTypography.textTheme.bodyMedium)
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 28),
                  SnapTextField(
                    label: 'Full Name',
                    hint: 'Arjun Mehta',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: Validators.name,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  const SizedBox(height: 14),
                  SnapTextField(
                    label: 'Email',
                    hint: 'you@example.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: Validators.email,
                    textCapitalization: TextCapitalization.none,
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  const SizedBox(height: 14),
                  SnapTextField(
                    label: 'Password',
                    controller: _passCtrl,
                    obscureText: _obscure,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: Validators.password,
                    textCapitalization: TextCapitalization.none,
                    suffix: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                          size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 14),
                  SnapTextField(
                    label: 'Monthly Income (₹)',
                    hint: '50000',
                    controller: _incomeCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v != null && v.isEmpty ? null :
                        Validators.amount(v),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                  const SizedBox(height: 28),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) => SizedBox(
                      width: double.infinity,
                      child: GlowButton(
                        label: 'Create Account',
                        isLoading: state is AuthLoading,
                        onPressed: _submit,
                        icon: Icons.check_rounded,
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: AppTypography.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded,
              color: AppColors.background, size: 26),
        ),
        const SizedBox(width: 12),
        Text(
          'SpendSnap',
          style: AppTypography.textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
