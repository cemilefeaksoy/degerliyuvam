String resolveImageUrl(String baseUrl, String path) {
  final value = path.trim();
  if (value.isEmpty) {
    return '';
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  if (value.startsWith('/')) {
    return '$baseUrl$value';
  }

  return '$baseUrl/$value';
}
