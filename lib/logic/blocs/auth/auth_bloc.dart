import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _repo = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthPasswordResetRequested>(_onPasswordReset);
  }

  final AuthRepository _repo;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final user = _repo.currentUser;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final profile = await _repo.fetchProfile(user.uid);
      if (profile != null) {
        emit(AuthAuthenticated(profile: profile));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final profile = await _repo.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        monthlyIncome: event.monthlyIncome,
      );
      emit(AuthAuthenticated(profile: profile));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final profile =
          await _repo.signIn(email: event.email, password: event.password);
      emit(AuthAuthenticated(profile: profile));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code, e.message)));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    await _repo.signOut();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordReset(
      AuthPasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _repo.sendPasswordReset(event.email);
      emit(const AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code, e.message)));
    }
  }

  String _mapFirebaseError(String code, [String? message]) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'email-already-in-use': return 'Email is already registered.';
      case 'weak-password': return 'Password is too weak (min 6 characters).';
      case 'invalid-email': return 'Invalid email address.';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      case 'operation-not-allowed': return 'Email/password sign-in is not enabled in Firebase Console.';
      case 'network-request-failed': return 'No internet connection. Please try again.';
      case 'channel-error': return 'Firebase channel error — check authorized domains in Firebase Console.';
      default: return 'Error [$code]: ${message ?? 'Please try again.'}';
    }
  }
}
