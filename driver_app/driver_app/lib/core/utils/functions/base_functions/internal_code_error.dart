// ignore_for_file: prefer_single_quotes, public_member_api_docs, lines_longer_than_80_chars

enum InternalCodeExtension {
  invalidCredentials('INVALID_CREDENTIALS', 'The provided credentials are invalid.'),
  userNotFound('USER_NOT_FOUND', 'No user found with the given information.'),
  serverError('SERVER_ERROR', 'A server error occurred. Please try again later.'),
  networkError('NETWORK_ERROR', 'Please check your internet connection and try again.');

  final String code;
  final String message;

  const InternalCodeExtension(this.code, this.message);

  static InternalCodeExtension? fromString(String? code) {
    for (final value in InternalCodeExtension.values) {
      if (value.code == code) {
        return value;
      }
    }
    return null;
  }
}
String getMessageFromInternalCode(String? internalCode) {
  final code = InternalCodeExtension.fromString(internalCode);
  return code?.message ?? "An unknown error occurred.";
}