import 'package:doc_genie/utils/text_utils.dart';

class Validators {
  const Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!value.isValidEmail) return 'Enter a valid email';
    return null;
  }

  static String? employeeCode(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee code is required';
    }
    if (value.trim().length < minLength) {
      return 'Enter a valid employee code';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }
}
