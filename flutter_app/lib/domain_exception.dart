/// Error carrying a message that is safe to show directly to the user.
class DomainException implements Exception {
  const DomainException(this.message);
  final String message;

  @override
  String toString() => message;
}
