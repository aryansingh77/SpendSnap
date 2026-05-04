import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'logic/blocs/budget/budget_bloc.dart';
import 'logic/blocs/goal/goal_bloc.dart';
import 'logic/blocs/transaction/transaction_bloc.dart';
import 'data/models/budget_model.dart';
import 'data/models/goal_model.dart';
import 'data/models/transaction_model.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/signup_screen.dart';
import 'ui/screens/budgets/add_budget_screen.dart';
import 'ui/screens/budgets/budgets_screen.dart';
import 'ui/screens/dashboard/dashboard_screen.dart';
import 'ui/screens/goals/add_goal_screen.dart';
import 'ui/screens/goals/goals_screen.dart';
import 'ui/screens/insights/insights_screen.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/profile/profile_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/transactions/add_transaction_screen.dart';
import 'ui/screens/transactions/transactions_screen.dart';

class SpendSnapApp extends StatefulWidget {
  const SpendSnapApp({super.key});

  @override
  State<SpendSnapApp> createState() => _SpendSnapAppState();
}

class _SpendSnapAppState extends State<SpendSnapApp> {
  final _authRepo = AuthRepository();
  final _txnRepo = TransactionRepository();
  final _budgetRepo = BudgetRepository();
  final _goalRepo = GoalRepository();

  late final AuthBloc _authBloc;
  late final TransactionBloc _txnBloc;
  late final BudgetBloc _budgetBloc;
  late final GoalBloc _goalBloc;
  StreamSubscription<TransactionState>? _txnBudgetSync;

  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: _authRepo)
      ..add(const AuthStarted());
    _txnBloc = TransactionBloc(repository: _txnRepo);
    _budgetBloc = BudgetBloc(repository: _budgetRepo);
    _goalBloc = GoalBloc(repository: _goalRepo);

    // Whenever transactions change, recalculate category spending and push to BudgetBloc
    _txnBudgetSync = _txnBloc.stream.listen(_syncBudgetSpending);

    _router = _buildRouter();
  }

  void _syncBudgetSpending(TransactionState txnState) {
    if (txnState.status != TransactionStatus.loaded) return;
    final now = DateTime.now();
    final spentMap = <String, double>{};
    for (final t in txnState.allTransactions) {
      if (t.isExpense &&
          t.date.month == now.month &&
          t.date.year == now.year) {
        spentMap[t.category] = (spentMap[t.category] ?? 0) + t.amount;
      }
    }
    _budgetBloc.add(BudgetSpentUpdated(spentMap: spentMap));
  }

  @override
  void dispose() {
    _txnBudgetSync?.cancel();
    _authBloc.close();
    _txnBloc.close();
    _budgetBloc.close();
    _goalBloc.close();
    super.dispose();
  }

  GoRouter _buildRouter() {
    final authNotifier = _AuthNotifier(_authBloc);

    return GoRouter(
      refreshListenable: authNotifier,
      initialLocation: '/splash',
      redirect: (context, state) {
        final authState = _authBloc.state;
        final onAuth = authState is AuthAuthenticated;
        final onSplash = state.matchedLocation == '/splash';
        final onLogin = state.matchedLocation == '/login';
        final onSignup = state.matchedLocation == '/signup';
        final onForgot = state.matchedLocation == '/forgot-password';

        if (authState is AuthInitial) return '/splash';
        if (onAuth && (onLogin || onSignup || onSplash)) return '/';
        if (!onAuth && onSplash) return '/login';
        if (!onAuth && !onLogin && !onSignup && !onForgot) return '/login';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const _ForgotPasswordScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MultiProvider(
            blocs: [_txnBloc, _budgetBloc, _goalBloc],
            child: MainShell(navigationShell: shell),
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/transactions',
                  builder: (_, __) => const TransactionsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/budgets',
                  builder: (_, __) => const BudgetsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/goals',
                  builder: (_, __) => const GoalsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/insights',
                  builder: (_, __) => const InsightsScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '/add-transaction',
          builder: (_, state) => AddTransactionScreen(
            existingTransaction: state.extra as TransactionModel?,
          ),
        ),
        GoRoute(
          path: '/add-budget',
          builder: (_, state) => AddBudgetScreen(
            existingBudget: state.extra as BudgetModel?,
          ),
        ),
        GoRoute(
          path: '/add-goal',
          builder: (_, state) => AddGoalScreen(
            existingGoal: state.extra as GoalModel?,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: _authRepo),
        RepositoryProvider<TransactionRepository>.value(value: _txnRepo),
        RepositoryProvider<BudgetRepository>.value(value: _budgetRepo),
        RepositoryProvider<GoalRepository>.value(value: _goalRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<TransactionBloc>.value(value: _txnBloc),
          BlocProvider<BudgetBloc>.value(value: _budgetBloc),
          BlocProvider<GoalBloc>.value(value: _goalBloc),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          bloc: _authBloc,
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              final uid = state.profile.uid;
              final now = DateTime.now();
              _txnBloc.add(TransactionStreamStarted(userId: uid));
              _budgetBloc.add(BudgetStreamStarted(
                  userId: uid, month: now.month, year: now.year));
              _goalBloc.add(GoalStreamStarted(userId: uid));
            }
          },
          child: MaterialApp.router(
            title: 'SpendSnap',
            theme: AppTheme.dark,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}

/// Helper to provide multiple blocs at once via StatefulShell.
class MultiProvider extends StatelessWidget {
  const MultiProvider({
    super.key,
    required this.blocs,
    required this.child,
  });
  final List<BlocBase> blocs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget w = child;
    for (final b in blocs.reversed) {
      if (b is TransactionBloc) {
        w = BlocProvider<TransactionBloc>.value(value: b, child: w);
      } else if (b is BudgetBloc) {
        w = BlocProvider<BudgetBloc>.value(value: b, child: w);
      } else if (b is GoalBloc) {
        w = BlocProvider<GoalBloc>.value(value: b, child: w);
      }
    }
    return w;
  }
}

/// GoRouter refresh notifier backed by AuthBloc.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();
  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent!')),
          );
          context.go('/login');
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Enter your email to receive a password reset link.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!re.hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon:
                      Icon(Icons.mail_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            context.read<AuthBloc>().add(
                                  AuthPasswordResetRequested(
                                      email: _ctrl.text.trim()),
                                );
                          },
                    child: state is AuthLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Reset Email'),
                  ),
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
