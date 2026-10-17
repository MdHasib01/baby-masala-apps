import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import 'app_data_controller.dart';
import 'providers.dart';

/// Same values as `AuthState` in babyCareService.ts, plus `starting`/`loading`.
enum AuthStage { starting, loading, welcome, signup, login, verify, membership, app }

@immutable
class SessionState {
  const SessionState({
    this.stage = AuthStage.starting,
    this.loadError,
    this.tempContact = '',
    this.tempName = '',
    this.isLoginMode = true,
  });

  final AuthStage stage;
  final String? loadError;
  final String tempContact;
  final String tempName;
  final bool isLoginMode;

  SessionState copyWith({
    AuthStage? stage,
    String? loadError,
    bool clearError = false,
    String? tempContact,
    String? tempName,
    bool? isLoginMode,
  }) =>
      SessionState(
        stage: stage ?? this.stage,
        loadError: clearError ? null : (loadError ?? this.loadError),
        tempContact: tempContact ?? this.tempContact,
        tempName: tempName ?? this.tempName,
        isLoginMode: isLoginMode ?? this.isLoginMode,
      );
}

/// Auth flow + bootstrap loading. Port of the auth logic in frontend/src/App.tsx.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.read(apiClientProvider).onUnauthorized = _onUnauthorized;
    return const SessionState();
  }

  AppDataController get _data => ref.read(appDataProvider.notifier);

  /// Called once from main(): restore token, then load or show Welcome.
  Future<void> start() async {
    final token = await ref.read(tokenStoreProvider).load();
    if (token != null && token.isNotEmpty) {
      await loadApp();
    } else {
      state = state.copyWith(stage: AuthStage.welcome);
    }
  }

  void goTo(AuthStage stage) => state = state.copyWith(stage: stage, clearError: true);

  Future<void> requestLoginOtp(String contact) async {
    await ref.read(apiProvider).requestOtp(contact: contact, mode: 'login');
    state = state.copyWith(tempContact: contact, isLoginMode: true, stage: AuthStage.verify);
  }

  Future<void> requestSignupOtp(String name, String contact) async {
    await ref.read(apiProvider).requestOtp(contact: contact, mode: 'signup', name: name);
    state = state.copyWith(tempContact: contact, tempName: name, isLoginMode: false, stage: AuthStage.verify);
  }

  Future<void> resendOtp() => ref.read(apiProvider).requestOtp(
        contact: state.tempContact,
        mode: state.isLoginMode ? 'login' : 'signup',
        name: state.isLoginMode ? null : state.tempName,
      );

  Future<void> verifyOtp(String code) => ref.read(apiProvider).verifyOtp(state.tempContact, code);

  /// Loads all data and enters the app (or the membership screen).
  Future<void> loadApp() async {
    state = state.copyWith(stage: AuthStage.loading, clearError: true);
    try {
      final b = await ref.read(apiProvider).bootstrap();
      _data.applyBootstrap(b);
      state = state.copyWith(stage: b.user.isMember ? AuthStage.app : AuthStage.membership);
    } catch (e) {
      if (ref.read(tokenStoreProvider).current == null) return; // 401 already reset us
      final msg = e is ApiException && e.code == 'NETWORK' ? e.message : ApiException.updatingMessage;
      state = state.copyWith(stage: AuthStage.loading, loadError: msg);
    }
  }

  void finishMembership() => state = state.copyWith(stage: AuthStage.app);

  Future<void> logout() async {
    await _data.flush();
    await ref.read(tokenStoreProvider).clear();
    _reset();
  }

  void _onUnauthorized() => _reset();

  void _reset() {
    _data.clear();
    state = const SessionState(stage: AuthStage.welcome);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
