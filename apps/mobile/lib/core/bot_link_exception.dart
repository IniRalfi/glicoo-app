/// Exception thrown when user tries to connect to a different bot platform
/// while already connected to another platform.
///
/// This enforces exclusive connection: user can only connect to ONE platform
/// (Telegram OR WhatsApp) at a time.
class BotLinkException implements Exception {
  final String message;
  final String? connectedPlatform;

  BotLinkException(this.message, this.connectedPlatform);

  @override
  String toString() => message;
}
