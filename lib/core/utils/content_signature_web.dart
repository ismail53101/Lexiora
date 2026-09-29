import 'dart:convert';

String contentSignature(Iterable<String> chunks) {
  int hash = 0x811c9dc5;
  const int prime = 0x01000193;
  for (final String chunk in chunks) {
    for (final int byte in utf8.encode(chunk)) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
  }
  return hash.toUnsigned(32).toRadixString(16);
}
