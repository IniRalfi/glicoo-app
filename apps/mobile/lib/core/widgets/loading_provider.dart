// loading_provider.dart
//
// Global loading overlay provider — show/hide loading dari mana saja.
//
// Purpose:
// Menyediakan state loading global yang bisa dipanggil dari screen manapun.
// Loading ditampilkan sebagai overlay di atas semua konten.
//
// Used By:
// main.dart (overlay), semua screen yang butuh loading
//
// Depends On:
// hooks_riverpod, freezed
//
// Impact:
// Global loading state

import 'package:hooks_riverpod/hooks_riverpod.dart';

/// State untuk loading overlay.
class LoadingState {
  final bool isLoading;
  final String title;
  final String? subtitle;

  const LoadingState({
    this.isLoading = false,
    this.title = 'Bentar yaa',
    this.subtitle,
  });

  LoadingState copyWith({bool? isLoading, String? title, String? subtitle}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}

/// Controller untuk loading overlay.
class LoadingController extends StateNotifier<LoadingState> {
  LoadingController() : super(const LoadingState());

  /// Tampilkan loading overlay.
  void show({String title = 'Bentar yaa', String? subtitle}) {
    state = LoadingState(isLoading: true, title: title, subtitle: subtitle);
  }

  /// Sembunyikan loading overlay.
  void hide() {
    state = state.copyWith(isLoading: false);
  }
}

/// Provider global untuk loading overlay.
final loadingProvider = StateNotifierProvider<LoadingController, LoadingState>((
  ref,
) {
  return LoadingController();
});
