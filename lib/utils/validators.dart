/// Utility functions for form validation
class Validators {
  Validators._(); // Private constructor to prevent instantiation

  /// Validates email format using regex
  ///
  /// Returns `true` if the email is in a valid format, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool isValid = Validators.isValidEmail('user@example.com'); // true
  /// bool isInvalid = Validators.isValidEmail('invalid-email'); // false
  /// ```
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    // Email validation regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Validates password strength using regex
  ///
  /// Returns `true` if the password meets all requirements:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter (A-Z)
  /// - At least 1 lowercase letter (a-z)
  /// - At least 1 number (0-9)
  /// - At least 1 special character (@, #, $, %, ^, &, *, !, etc.)
  ///
  /// Example:
  /// ```dart
  /// bool isStrong = Validators.isStrongPassword('MyPass123!'); // true
  /// bool isWeak = Validators.isStrongPassword('weak'); // false
  /// ```
  static bool isStrongPassword(String password) {
    if (password.isEmpty) return false;

    // Check minimum length (8 characters)
    if (password.length < 8) return false;

    // Check for at least 1 uppercase letter
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);

    // Check for at least 1 lowercase letter
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);

    // Check for at least 1 number
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    // Check for at least 1 special character
    final hasSpecialChar = RegExp(
      r'[!@#$%^&*(),.?":{}|<>~`+=\-_\[\]\\;/]',
    ).hasMatch(password);

    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
  }

  /// Validates if full name contains at least 2 words
  ///
  /// Returns `true` if full name has at least 2 words, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool isValid = Validators.isValidFullName('John Smith'); // true
  /// bool isInvalid = Validators.isValidFullName('John'); // false
  /// ```
  static bool isValidFullName(String fullName) {
    if (fullName.trim().isEmpty) return false;

    // Split by whitespace and filter out empty strings
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words.length >= 2;
  }

  /// Validates phone number format
  ///
  /// Returns `true` if phone contains 8-15 digits, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool isValid = Validators.isValidPhone('01234567890'); // true
  /// bool isInvalid = Validators.isValidPhone('123'); // false
  /// ```
  static bool isValidPhone(String phone) {
    if (phone.trim().isEmpty) return false;

    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Phone validation: 8-15 digits total
    return digitsOnly.length >= 8 && digitsOnly.length <= 15;
  }

  /// Returns a descriptive error message for invalid emails
  ///
  /// Returns `null` if email is valid, otherwise returns an error message.
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Returns a descriptive error message for weak passwords
  ///
  /// Returns `null` if password is strong, otherwise returns an error message.
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>~`+=\-_\[\]\\;/]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validates if two passwords match
  ///
  /// Returns `null` if passwords match, otherwise returns an error message.
  static String? validatePasswordConfirmation(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates if a name is not empty and has reasonable length
  ///
  /// Returns `null` if name is valid, otherwise returns an error message.
  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (name.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validates full name to ensure it contains at least 2 words
  ///
  /// Returns `null` if name is valid, otherwise returns an error message.
  static String? validateFullName(String fullName) {
    if (fullName.trim().isEmpty) {
      return 'Full name is required';
    }

    // Split by whitespace and filter out empty strings
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.length < 2) {
      return 'Please enter at least first and last name';
    }

    if (fullName.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (fullName.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  /// Validates phone number format
  ///
  /// Returns `null` if phone is valid, otherwise returns an error message.
  static String? validatePhone(String phone) {
    if (phone.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 8) {
      return 'Phone number must be at least 8 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    return null;
  }

  /// Validates city name
  ///
  /// Returns `null` if city is valid, otherwise returns an error message.
  static String? validateCity(String city) {
    if (city.trim().isEmpty) {
      return 'City is required';
    }
    if (city.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    if (city.trim().length > 30) {
      return 'City name must be less than 30 characters';
    }
    return null;
  }

  /// Validates district name
  ///
  /// Returns `null` if district is valid, otherwise returns an error message.
  static String? validateDistrict(String district) {
    if (district.trim().isEmpty) {
      return 'District is required';
    }
    if (district.trim().length < 2) {
      return 'District name must be at least 2 characters';
    }
    if (district.trim().length > 30) {
      return 'District name must be less than 30 characters';
    }
    return null;
  }
}
