/// Normalizes a URL for consistent comparison by standardizing scheme/host casing and stripping trailing slashes.
String normalizeUrl(String url) {
  final parsed = Uri.tryParse(url.trim());
  if (parsed == null) {
    return url.trim().replaceAll(RegExp(r'/$'), '').toLowerCase();
  }
  return parsed.toString().replaceAll(RegExp(r'/$'), '').toLowerCase();
}
