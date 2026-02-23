abstract class BaseNavigationArgs {
  const BaseNavigationArgs();

  /// Returns true if the arguments are valid and sufficient to build the page.
  bool get isValid;

  /// Returns a user-friendly error message if validation fails.
  String? get errorMessage;
}
