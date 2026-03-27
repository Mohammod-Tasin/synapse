import 'dart:async';
import 'dart:io';

/// Translates raw, technical exceptions into human-readable, user-friendly messages.
String getFriendlyErrorMessage(Object e) {
  if (e is TimeoutException) {
    return 'Connection timed out. Please check your internet and try again.';
  } else if (e is SocketException) {
    return 'No internet connection. Please check your network.';
  } else if (e is FormatException) {
    return 'Unexpected data format received from the server.';
  } else if (e is Exception) {
    // Attempt to extract the clean error message sent by the FastAPI backend.
    final message = e.toString().replaceAll('Exception: ', '').trim();
    if (message.isNotEmpty && message.toLowerCase() != 'exception') {
      return message;
    }
    return 'Server error. Please try again later.';
  }
  
  return 'Something went wrong. Please try again.';
}
