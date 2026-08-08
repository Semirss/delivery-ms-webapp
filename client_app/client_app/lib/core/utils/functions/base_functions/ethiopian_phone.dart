const String ethiopianDialCode = '+251';

String normalizeEthiopianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  if (digits.length == 12 &&
      digits.startsWith('251') &&
      (digits[3] == '7' || digits[3] == '9')) {
    return '+251${digits.substring(3)}';
  }

  if (digits.length == 10 &&
      digits.startsWith('0') &&
      (digits[1] == '7' || digits[1] == '9')) {
    return '+251${digits.substring(1)}';
  }

  if (digits.length == 9 && (digits[0] == '7' || digits[0] == '9')) {
    return '+251$digits';
  }

  return value.trim();
}

String ethiopianPhoneInputText(String value) {
  final normalized = normalizeEthiopianPhone(value);
  if (normalized.startsWith(ethiopianDialCode)) {
    return normalized.substring(ethiopianDialCode.length);
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10 && digits.startsWith('0')) {
    return digits.substring(1);
  }
  return value.trim();
}

bool isValidEthiopianPhone(String value) {
  return RegExp(r'^\+251[79]\d{8}$').hasMatch(normalizeEthiopianPhone(value));
}

String? validateEthiopianPhone(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Please enter your phone number';
  if (!isValidEthiopianPhone(raw)) {
    return 'Use an Ethiopian phone number, for example +251 912 345 678';
  }
  return null;
}
