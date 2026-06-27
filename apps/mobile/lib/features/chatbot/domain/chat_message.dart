// chat_message.dart
//
// Purpose:
// Data model for In-App Chatbot messages.
//
// Used By:
// chatbot_provider.dart, chatbot_screen.dart
//
// Depends On:
// None (Pure Dart object)
//
// Impact:
// Data representation of chatbot message history.

class ChatMessage {
  final String id;
  final String text;
  final String sender; // 'user' | 'ai'
  final DateTime timestamp;
  final bool isFood;
  final int? estimatedCalories;
  final double? estimatedSugarGrams;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isFood = false,
    this.estimatedCalories,
    this.estimatedSugarGrams,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'isFood': isFood,
      'estimatedCalories': estimatedCalories,
      'estimatedSugarGrams': estimatedSugarGrams,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: json['sender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFood: json['isFood'] as bool? ?? false,
      estimatedCalories: json['estimatedCalories'] as int?,
      estimatedSugarGrams: (json['estimatedSugarGrams'] as num?)?.toDouble(),
    );
  }
}
