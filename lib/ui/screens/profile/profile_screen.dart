import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/snap_text_field.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _incomeCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile =
        (context.read<AuthBloc>().state as AuthAuthenticated).profile;
    _incomeCtrl =
        TextEditingController(text: profile.monthlyIncome.toInt().toString());
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIncome(UserProfileModel profile) async {
    final val = double.tryParse(_incomeCtrl.text);
    if (val == null) return;
    setState(() => _saving = true);
    final updated = profile.copyWith(monthlyIncome: val);
    await context.read<AuthRepository>().updateProfile(updated);
    if (mounted) setState(() { _editing = false; _saving = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Monthly income updated'),
            ],
          ),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        (context.read<AuthBloc>().state as AuthAuthenticated).profile;
    final initials = profile.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            _AvatarSection(initials: initials, profile: profile)
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 32),

            // ── Account Info ──────────────────────────────────────────────
            _SectionHeader(label: 'Account Info'),
            const SizedBox(height: 10),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.secondary,
                  label: 'Display Name',
                  value: profile.name,
                ),
                _MenuDivider(),
                _MenuTile(
                  icon: Icons.mail_outline_rounded,
                  iconColor: AppColors.primary,
                  label: 'Email Address',
                  value: profile.email,
                ),
              ],
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),

            const SizedBox(height: 24),

            // ── Financial ─────────────────────────────────────────────────
            _SectionHeader(label: 'Financial'),
            const SizedBox(height: 10),
            _IncomeCard(
              profile: profile,
              editing: _editing,
              saving: _saving,
              incomeCtrl: _incomeCtrl,
              onEditToggle: () => setState(() => _editing = !_editing),
              onSave: () => _saveIncome(profile),
            ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08),

            const SizedBox(height: 24),

            // ── App ───────────────────────────────────────────────────────
            _SectionHeader(label: 'App'),
            const SizedBox(height: 10),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.insights_outlined,
                  iconColor: AppColors.catBills,
                  label: 'Insights',
                  onTap: () {
                    context.pop();
                    context.go('/insights');
                  },
                ),
                _MenuDivider(),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.warning,
                  label: 'Budget & Goals',
                  onTap: () {
                    context.pop();
                    context.go('/budgets');
                  },
                ),
                _MenuDivider(),
                _MenuTile(
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.catSavings,
                  label: 'Savings Goals',
                  onTap: () {
                    context.pop();
                    context.go('/goals');
                  },
                ),
              ],
            ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),

            const SizedBox(height: 32),

            // ── Sign Out ──────────────────────────────────────────────────
            _SignOutButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const AuthSignOutRequested()),
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),
          ],
        ),
      ),
    );
  }
}

// ── Avatar Section ────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.initials, required this.profile});
  final String initials;
  final UserProfileModel profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  backgroundColor: AppColors.surfaceElevated,
                  child: Text(
                    initials,
                    style: AppTypography.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning,
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          profile.name,
          style: AppTypography.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              profile.email,
              style: AppTypography.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Menu Group ────────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 54),
      color: AppColors.cardBorder,
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.textTheme.titleMedium),
                    if (value != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        style: AppTypography.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
      ),
    );
  }
}

// ── Income Card ───────────────────────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({
    required this.profile,
    required this.editing,
    required this.saving,
    required this.incomeCtrl,
    required this.onEditToggle,
    required this.onSave,
  });
  final UserProfileModel profile;
  final bool editing;
  final bool saving;
  final TextEditingController incomeCtrl;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: editing
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
        boxShadow: editing
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                          size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monthly Income',
                              style: AppTypography.textTheme.titleMedium),
                          Text('Used for budget tracking',
                              style: AppTypography.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onEditToggle,
                      icon: Icon(
                        editing
                            ? Icons.close_rounded
                            : Icons.edit_rounded,
                        size: 14,
                      ),
                      label: Text(editing ? 'Cancel' : 'Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: editing
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (editing) ...[
                  SnapTextField(
                    label: 'New Amount (₹)',
                    controller: incomeCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee_rounded,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : onSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.background),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                          saving ? 'Saving…' : 'Save Changes',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(profile.monthlyIncome),
                        style:
                            AppTypography.textTheme.displayLarge?.copyWith(
                          fontSize: 30,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('/ month',
                            style: AppTypography.textTheme.bodySmall),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign Out Button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
        color: AppColors.expense.withValues(alpha: 0.06),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          splashColor: AppColors.expense.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded,
                    color: AppColors.expense, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
