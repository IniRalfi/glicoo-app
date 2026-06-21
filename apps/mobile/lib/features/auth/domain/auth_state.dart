import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// State autentikasi aplikasi.
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated({required String userId}) =
      _Authenticated;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.error({required String message}) = _Error;
}
