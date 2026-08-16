const String ethiopianDialCode = '+251';

String normalizeEthiopianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  if (digits.length == 12 && digits.startsWith('251') && digits[3] == '9') {
    return '0${digits.substring(3)}';
  }

  if (digits.length == 10 && digits.startsWith('0') && digits[1] == '9') {
    return digits;
  }

  if (digits.length == 9 && digits[0] == '9') {
    return '0$digits';
  }

  return value.trim();
}

String ethiopianPhoneInputText(String value) {
  final normalized = normalizeEthiopianPhone(value);
  return normalized.isEmpty ? value.trim() : normalized;
}

bool isValidEthiopianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'^09\d{8}$').hasMatch(digits);
}

String? validateEthiopianPhone(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Please enter your phone number';
  if (!isValidEthiopianPhone(raw)) {
    return 'Use an Ethiopian phone number starting with 09, for example 0912345678';
  }
  return null;
}
