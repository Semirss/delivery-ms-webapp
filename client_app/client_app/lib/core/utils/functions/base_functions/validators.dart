abstract class Validator {
  static String? phoneNumberValidator(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return "Please enter phone number";
    } else if (!RegExp(r"^[79]\d{8}$").hasMatch(phoneNumber)) {
      return "Please enter a valid phone number\nExample: +251 912 345 678";
    }
    return null;
  }

  static String? requiredValidator(String? name) {
    if (name == null || name.isEmpty) {
      return "This Field is required";
    }
    return null;
  }
}

bool isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
      .hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 6;
}

bool isValidPhoneNumber(String phone) {
  return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
}
