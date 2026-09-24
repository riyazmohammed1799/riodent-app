/// Input validators used across the application.
class Validators {
  Validators._();

  /// Validates an Indian phone number (10 digits, optionally prefixed with +91).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and country code prefix
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('+91', '');
    if (cleaned.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validates a 6-digit OTP code.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length != 6 || !RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  /// Validates a non-empty required field.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password (min 6 characters).
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates description text (min 10 characters).
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  /// Formats a phone number to E.164 format for Firebase Auth.
  static String toE164(String phone) {
    final cleaned = phone.trim().replaceAll(' ', '').replaceAll('+91', '');
    return '+91$cleaned';
  }
}
