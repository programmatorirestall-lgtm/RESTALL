// Small helpers to safely extract strings from dynamic maps returned by APIs.
String safeString(Map? map, String key) {
  if (map == null) return '';
  final val = map[key];
  if (val == null) return '';
  return val.toString();
}

String safeLower(Map? map, String key) => safeString(map, key).toLowerCase();

bool equalsIgnoreCase(Map? map, String key, String other) =>
    safeString(map, key).toLowerCase() == other.toLowerCase();
