import 'ethiopian_phone.dart';

abstract class Validator {
  static String? phoneNumberValidator(String? phoneNumber) {
    return validateEthiopianPhone(phoneNumber);
  }

  static String? requiredValidator(String? name) {
    if (name == null || name.isEmpty) {
      return "This Field is required";
    }
    return null;
  }
}

bool isValidEmail(String email) {
  return RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  ).hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

bool isValidPhoneNumber(String phone) {
  return isValidEthiopianPhone(phone);
}
