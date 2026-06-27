// chatbot_provider.dart
//
// Purpose:
// State notifier for in-app chatbot containing chat logs cached in local storage.
//
// Used By:
// chatbot_screen.dart
//
// Depends On:
// hooks_riverpod, shared_preferences, api_service, chat_message.dart

import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api_service.dart';
import '../domain/chat_message.dart';

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? errorMessage;

  ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.errorMessage,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier(this._apiService) : super(ChatbotState()) {
    _loadMessages();
  }

  final ApiService _apiService;
  static const _storageKey = 'glicoo_chat_history';

  /// [ID] Memuat riwayat chat dari SharedPreferences lokal.
  /// [EN] Loads chat history from local SharedPreferences.
  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null) {
        final List<dynamic> decodedList = jsonDecode(savedStr) as List<dynamic>;
        final messages = decodedList
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        // [ID] Chat pertama kali kosong, masukkan pesan sambutan default dari Iloo
        final welcomeMessage = ChatMessage(
          id: 'welcome',
          text: 'Halo! Aku Iloo, sahabat sehatmu. Kamu bisa mengobrol denganku atau mencatat makananmu secara langsung di sini. 😊',
          sender: 'ai',
          timestamp: DateTime.now(),
        );
        state = state.copyWith(messages: [welcomeMessage], isLoading: false);
        await _saveMessages([welcomeMessage]);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat riwayat chat: $e',
      );
    }
  }

  /// [ID] Menyimpan riwayat chat ke SharedPreferences.
  /// [EN] Saves chat history to SharedPreferences.
  Future<void> _saveMessages(List<ChatMessage> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((m) => m.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      // Failed to save logs silently
    }
  }

  /// [ID] Mengirim pesan dari pengguna ke backend dan menerima balasan AI dengan menyertakan metrik lokal.
  /// [EN] Sends user message to backend and receives AI reply containing local health context metrics.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: 'user',
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(messages: updatedMessages, isTyping: true, clearError: true);
    await _saveMessages(updatedMessages);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ambil data kesehatan lokal ter-update
      final steps = prefs.getInt('glico_daily_steps') ?? 0;
      final screenTime = prefs.getInt('glico_daily_screen_time') ?? 0;
      final age = prefs.getInt('glico_cached_profile_age');
      final weight = prefs.getDouble('glico_cached_profile_weight');
      final height = prefs.getDouble('glico_cached_profile_height');
      final waist = prefs.getDouble('lingkar_pinggang_cm');
      final findrisc = prefs.getInt('findrisc_score');

      final localContext = <String, dynamic>{
        'today_steps': steps,
        'today_screen_time_minutes': screenTime,
        if (age != null && age > 0) 'age': age,
        if (weight != null && weight > 0) 'weight': weight,
        if (height != null && height > 0) 'height': height,
        if (waist != null && waist > 0) 'waist_circumference': waist,
        'findrisc_score': ?findrisc,
      };

      final res = await _apiService.sendChatMessage(text, context: localContext);
      
      final replyText = res['reply'] as String;
      final isFood = res['isFood'] as bool? ?? false;
      final estimatedCalories = res['estimatedCalories'] as int?;
      final estimatedSugarGrams = (res['estimatedSugarGrams'] as num?)?.toDouble();

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: replyText,
        sender: 'ai',
        timestamp: DateTime.now(),
        isFood: isFood,
        estimatedCalories: estimatedCalories,
        estimatedSugarGrams: estimatedSugarGrams,
      );

      final finalMessages = [...state.messages, aiMsg];
      state = state.copyWith(messages: finalMessages, isTyping: false);
      await _saveMessages(finalMessages);
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        errorMessage: 'Koneksi bermasalah: $e',
      );
    }
  }

  /// [ID] Menghapus seluruh riwayat chat lokal.
  /// [EN] Clears all local chat history.
  Future<void> clearHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      
      final welcomeMessage = ChatMessage(
        id: 'welcome',
        text: 'Halo! Aku Iloo, sahabat sehatmu. Kamu bisa mengobrol denganku atau mencatat makananmu secara langsung di sini. 😊',
        sender: 'ai',
        timestamp: DateTime.now(),
      );
      state = ChatbotState(messages: [welcomeMessage]);
      await _saveMessages([welcomeMessage]);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus riwayat chat: $e',
      );
    }
  }
}

final chatbotStateProvider =
    StateNotifierProvider.autoDispose<ChatbotNotifier, ChatbotState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatbotNotifier(apiService);
});
