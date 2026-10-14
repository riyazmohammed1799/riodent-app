/// Input validators used across the application.
class Validators {
  Validators._();

  /// Validates an Indian phone number (strictly 10 digits, no more, no less).
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('+91', '');
    if (cleaned.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Phone number must be exactly 10 digits';
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
  /// Must contain @ and a dot after it with at least 2 letters after the last dot.
  /// Accepts modern TLDs like .dental, .clinic, .health.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
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

  /// Validates description text (any words, 1 to 500 characters, not only spaces).
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  /// Validates Hyderabad serviceable pincode (6 digits, must match configured prefix, e.g. 500, 501, 502).
  static String? pincode(String? value, [List<String> serviceablePrefixes = const ['500', '501', '502']]) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final cleaned = value.trim();
    if (cleaned.length != 6 || !RegExp(r'^\d{6}$').hasMatch(cleaned)) {
      return 'Enter a valid 6-digit pincode';
    }
    final matchesPrefix = serviceablePrefixes.any((prefix) => cleaned.startsWith(prefix));
    if (!matchesPrefix) {
      return 'We currently serve Hyderabad only.';
    }
    return null;
  }

  /// Validates the amount paid to the technician (whole rupees 0 to 100,000).
  static String? amountPaid(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final trimmed = value.trim();
    // Must be whole rupees only (no decimals)
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Enter a valid whole rupee amount';
    }
    final numVal = int.tryParse(trimmed);
    if (numVal == null) {
      return 'Enter a valid amount';
    }
    if (numVal < 0 || numVal > 100000) {
      return 'Amount must be between ₹0 and ₹1,00,000';
    }
    return null;
  }

  /// Formats a phone number to E.164 format for Firebase Auth.
  static String toE164(String phone) {
    final cleaned = phone.trim().replaceAll(' ', '').replaceAll('+91', '');
    return '+91$cleaned';
  }
}
