class Validators {
  Validators._();

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final price = double.tryParse(value.trim());
    if (price == null) return 'Enter a valid number';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }


  static String? optionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return isValid ? null : 'Enter a valid http(s) URL';
  }
}